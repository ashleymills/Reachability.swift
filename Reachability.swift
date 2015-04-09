/*
Copyright (c) 2014, Ashley Mills
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

1. Redistributions of source code must retain the above copyright notice, this
list of conditions and the following disclaimer.

2. Redistributions in binary form must reproduce the above copyright notice,
this list of conditions and the following disclaimer in the documentation
and/or other materials provided with the distribution.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
POSSIBILITY OF SUCH DAMAGE.
*/

import SystemConfiguration
import Foundation

let ReachabilityChangedNotification = "ReachabilityChangedNotification"

class Reachability: NSObject, Printable {
    
    typealias NetworkReachable = (Reachability) -> ()
    typealias NetworkUneachable = (Reachability) -> ()

    enum NetworkStatus: Printable {
        
        case NotReachable, ReachableViaWiFi, ReachableViaWWAN
        
        var description: String {
            switch self {
            case .ReachableViaWWAN:
                return "Cellular"
            case .ReachableViaWiFi:
                return "WiFi"
            case .NotReachable:
                return "No Connection"
            }
        }
    }
    
    // MARK: - *** Public properties ***
    
    var whenReachable: NetworkReachable?
    var whenUnreachable: NetworkUneachable?
    var reachableOnWWAN: Bool

    var currentReachabilityStatus: NetworkStatus {
        if isReachable() {
            if isReachableViaWiFi() {
                return .ReachableViaWiFi
            }
            if isRunningOnDevice {
                return .ReachableViaWWAN
            }
        }
        
        return .NotReachable
    }
    
    var currentReachabilityString: String {
        return "\(currentReachabilityStatus)"
    }
    
    // MARK: - *** Initialisation methods ***
    convenience init(hostname: String) {
        let ref = SCNetworkReachabilityCreateWithName(nil, (hostname as NSString).UTF8String).takeRetainedValue()
        self.init(reachabilityRef: ref)
    }
    
    class func reachabilityForInternetConnection() -> Reachability {
        
        var zeroAddress = sockaddr_in(sin_len: __uint8_t(0), sin_family: sa_family_t(0), sin_port: in_port_t(0), sin_addr: in_addr(s_addr: 0), sin_zero: (0, 0, 0, 0, 0, 0, 0, 0))
        zeroAddress.sin_len = UInt8(sizeofValue(zeroAddress))
        zeroAddress.sin_family = sa_family_t(AF_INET)
        
        let ref = withUnsafePointer(&zeroAddress) {
            SCNetworkReachabilityCreateWithAddress(kCFAllocatorDefault, UnsafePointer($0)).takeRetainedValue()
        }
        return Reachability(reachabilityRef: ref)
    }
    
    class func reachabilityForLocalWiFi() -> Reachability {
        
        var localWifiAddress: sockaddr_in = sockaddr_in(sin_len: __uint8_t(0), sin_family: sa_family_t(0), sin_port: in_port_t(0), sin_addr: in_addr(s_addr: 0), sin_zero: (0, 0, 0, 0, 0, 0, 0, 0))
        localWifiAddress.sin_len = UInt8(sizeofValue(localWifiAddress))
        localWifiAddress.sin_family = sa_family_t(AF_INET)
        
        // IN_LINKLOCALNETNUM is defined in <netinet/in.h> as 169.254.0.0
        let address: Int64 = 0xA9FE0000
        localWifiAddress.sin_addr.s_addr = in_addr_t(address.bigEndian)
        
        let ref = withUnsafePointer(&localWifiAddress) {
            SCNetworkReachabilityCreateWithAddress(kCFAllocatorDefault, UnsafePointer($0)).takeRetainedValue()
        }
        return Reachability(reachabilityRef: ref)
    }
    
    // MARK: - *** Notifier methods ***
    func startNotifier() -> Bool {
        
        reachabilityObject = self
        let reachability = self.reachabilityRef!
        
        previousReachabilityFlags = reachabilityFlags
        if let timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, timer_queue) {
            dispatch_source_set_timer(timer, dispatch_walltime(nil, 0), 500 * NSEC_PER_MSEC, 100 * NSEC_PER_MSEC)
            dispatch_source_set_event_handler(timer, { [unowned self] in
                self.timerFired()
            })
            
            dispatch_timer = timer
            dispatch_resume(timer)
            
            return true
        } else {
            return false
        }
    }
    
    func stopNotifier() {
        
        reachabilityObject = nil
        
        if let timer = dispatch_timer {
            dispatch_source_cancel(timer)
            dispatch_timer = nil
        }
        
    }
    
    // MARK: - *** Connection test methods ***
    func isReachable() -> Bool {
        return isReachableWithTest({ (flags: SCNetworkReachabilityFlags) -> (Bool) in
            return self.isReachableWithFlags(flags)
        })
    }
    
    func isReachableViaWWAN() -> Bool {
        
        if isRunningOnDevice {
            return isReachableWithTest() { flags -> Bool in
                // Check we're REACHABLE
                if self.isReachable(flags) {
                    
                    // Now, check we're on WWAN
                    if self.isOnWWAN(flags) {
                        return true
                    }
                }
                return false
            }
        }
        return false
    }
    
    func isReachableViaWiFi() -> Bool {
        
        return isReachableWithTest() { flags -> Bool in
            
            // Check we're reachable
            if self.isReachable(flags) {
                
                if self.isRunningOnDevice {
                    // Check we're NOT on WWAN
                    if self.isOnWWAN(flags) {
                        return false
                    }
                }
                return true
            }
            
            return false
        }
    }
    
    // MARK: - *** Private methods ***
    private var isRunningOnDevice: Bool = {
        #if (arch(i386) || arch(x86_64)) && os(iOS)
            return false
            #else
            return true
        #endif
        }()
    
    private var reachabilityRef: SCNetworkReachability?
    private var reachabilityObject: AnyObject?
    private var dispatch_timer: dispatch_source_t?
    private lazy var timer_queue: dispatch_queue_t = {
        return dispatch_queue_create("uk.co.joylordsystems.reachability_timer_queue", nil)
    }()
    private var previousReachabilityFlags: SCNetworkReachabilityFlags?
    
    private init(reachabilityRef: SCNetworkReachability) {
        reachableOnWWAN = true
        self.reachabilityRef = reachabilityRef
    }
    
    func timerFired() {
        let currentReachabilityFlags = reachabilityFlags
        if let _previousReachabilityFlags = previousReachabilityFlags {
            if currentReachabilityFlags != previousReachabilityFlags {
                dispatch_async(dispatch_get_main_queue(), { [unowned self] in
                    self.reachabilityChanged(currentReachabilityFlags)
                    self.previousReachabilityFlags = currentReachabilityFlags
                })
            }
        }
    }
    
    private func reachabilityChanged(flags: SCNetworkReachabilityFlags) {
        if isReachableWithFlags(flags) {
            if let block = whenReachable {
                block(self)
            }
        } else {
            if let block = whenUnreachable {
                block(self)
            }
        }
        
        NSNotificationCenter.defaultCenter().postNotificationName(ReachabilityChangedNotification, object:self)
    }
    
    private func isReachableWithFlags(flags: SCNetworkReachabilityFlags) -> Bool {
        
        let reachable = isReachable(flags)
        
        if !reachable {
            return false
        }
        
        if isConnectionRequiredOrTransient(flags) {
            return false
        }
        
        if isRunningOnDevice {
            if isOnWWAN(flags) && !reachableOnWWAN {
                // We don't want to connect when on 3G.
                return false
            }
        }
        
        return true
    }
    
    private func isReachableWithTest(test: (SCNetworkReachabilityFlags) -> (Bool)) -> Bool {
        var flags: SCNetworkReachabilityFlags = 0
        let gotFlags = SCNetworkReachabilityGetFlags(reachabilityRef, &flags) != 0
        if gotFlags {
            return test(flags)
        }
        
        return false
    }
    
    // WWAN may be available, but not active until a connection has been established.
    // WiFi may require a connection for VPN on Demand.
    private func isConnectionRequired() -> Bool {
        return connectionRequired()
    }
    
    private func connectionRequired() -> Bool {
        return isReachableWithTest({ (flags: SCNetworkReachabilityFlags) -> (Bool) in
            return self.isConnectionRequired(flags)
        })
    }
    
    // Dynamic, on demand connection?
    private func isConnectionOnDemand() -> Bool {
        return isReachableWithTest({ (flags: SCNetworkReachabilityFlags) -> (Bool) in
            return self.isConnectionRequired(flags) && self.isConnectionOnTrafficOrDemand(flags)
        })
    }
    
    // Is user intervention required?
    private func isInterventionRequired() -> Bool {
        return isReachableWithTest({ (flags: SCNetworkReachabilityFlags) -> (Bool) in
            return self.isConnectionRequired(flags) && self.isInterventionRequired(flags)
        })
    }
    
    private func isOnWWAN(flags: SCNetworkReachabilityFlags) -> Bool {
        return flags & SCNetworkReachabilityFlags(kSCNetworkReachabilityFlagsIsWWAN) != 0
    }
    private func isReachable(flags: SCNetworkReachabilityFlags) -> Bool {
        return flags & SCNetworkReachabilityFlags(kSCNetworkReachabilityFlagsReachable) != 0
    }
    private func isConnectionRequired(flags: SCNetworkReachabilityFlags) -> Bool {
        return flags & SCNetworkReachabilityFlags(kSCNetworkReachabilityFlagsConnectionRequired) != 0
    }
    private func isInterventionRequired(flags: SCNetworkReachabilityFlags) -> Bool {
        return flags & SCNetworkReachabilityFlags(kSCNetworkReachabilityFlagsInterventionRequired) != 0
    }
    private func isConnectionOnTraffic(flags: SCNetworkReachabilityFlags) -> Bool {
        return flags & SCNetworkReachabilityFlags(kSCNetworkReachabilityFlagsConnectionOnTraffic) != 0
    }
    private func isConnectionOnDemand(flags: SCNetworkReachabilityFlags) -> Bool {
        return flags & SCNetworkReachabilityFlags(kSCNetworkReachabilityFlagsConnectionOnDemand) != 0
    }
    func isConnectionOnTrafficOrDemand(flags: SCNetworkReachabilityFlags) -> Bool {
        return flags & SCNetworkReachabilityFlags(kSCNetworkReachabilityFlagsConnectionOnTraffic | kSCNetworkReachabilityFlagsConnectionOnDemand) != 0
    }
    private func isTransientConnection(flags: SCNetworkReachabilityFlags) -> Bool {
        return flags & SCNetworkReachabilityFlags(kSCNetworkReachabilityFlagsTransientConnection) != 0
    }
    private func isLocalAddress(flags: SCNetworkReachabilityFlags) -> Bool {
        return flags & SCNetworkReachabilityFlags(kSCNetworkReachabilityFlagsIsLocalAddress) != 0
    }
    private func isDirect(flags: SCNetworkReachabilityFlags) -> Bool {
        return flags & SCNetworkReachabilityFlags(kSCNetworkReachabilityFlagsIsDirect) != 0
    }
    private func isConnectionRequiredOrTransient(flags: SCNetworkReachabilityFlags) -> Bool {
        let testcase = SCNetworkReachabilityFlags(kSCNetworkReachabilityFlagsConnectionRequired | kSCNetworkReachabilityFlagsTransientConnection)
        return flags & testcase == testcase
    }
    
    private var reachabilityFlags: SCNetworkReachabilityFlags {
        var flags: SCNetworkReachabilityFlags = 0
        let gotFlags = SCNetworkReachabilityGetFlags(reachabilityRef, &flags) != 0
        if gotFlags {
            return flags
        }
        
        return 0
    }
    
    override var description: String {
        
        var W: String
        if isRunningOnDevice {
            W = isOnWWAN(reachabilityFlags) ? "W" : "-"
        } else {
            W = "X"
        }
        let R = isReachable(reachabilityFlags) ? "R" : "-"
        let c = isConnectionRequired(reachabilityFlags) ? "c" : "-"
        let t = isTransientConnection(reachabilityFlags) ? "t" : "-"
        let i = isInterventionRequired(reachabilityFlags) ? "i" : "-"
        let C = isConnectionOnTraffic(reachabilityFlags) ? "C" : "-"
        let D = isConnectionOnDemand(reachabilityFlags) ? "D" : "-"
        let l = isLocalAddress(reachabilityFlags) ? "l" : "-"
        let d = isDirect(reachabilityFlags) ? "d" : "-"
        
        return "\(W)\(R) \(c)\(t)\(i)\(C)\(D)\(l)\(d)"
    }
    
    deinit {
        stopNotifier()
        
        reachabilityRef = nil
        whenReachable = nil
        whenUnreachable = nil
    }
}


