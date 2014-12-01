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
    
    enum NetworkStatus {
        // Apple NetworkStatus Compatible Names.
        case NotReachable, ReachableViaWiFi, ReachableViaWWAN
    }
    
    var isRunningOnDevice: Bool = {
        #if (arch(i386) || arch(x86_64)) && os(iOS)
            return false
            #else
            return true
        #endif
        }()
    
    private var reachabilityRef: SCNetworkReachability?
    //    private var reachabilitySerialQueue: dispatch_queue_t?
    private var reachabilityObject: AnyObject?
    var reachableBlock: NetworkReachable?
    var unreachableBlock: NetworkUneachable?
    var reachableOnWWAN: Bool
    private var timer: NSTimer?
    private var previousReachabilityFlags: SCNetworkReachabilityFlags?
    
    init(reachabilityRef: SCNetworkReachability) {
        reachableOnWWAN = true;
        self.reachabilityRef = reachabilityRef;
    }
    
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
        localWifiAddress.sin_addr.s_addr = in_addr_t(Int64(0xA9FE0000).bigEndian)
        
        let ref = withUnsafePointer(&localWifiAddress) {
            SCNetworkReachabilityCreateWithAddress(kCFAllocatorDefault, UnsafePointer($0)).takeRetainedValue()
        }
        return Reachability(reachabilityRef: ref)
    }
    
    func startNotifier() -> Bool {
        
        reachabilityObject = self
        let reachability = self.reachabilityRef!
        
        previousReachabilityFlags = reachabilityFlags;
        timer = NSTimer.scheduledTimerWithTimeInterval(0.5, target: self, selector: "timerFired:", userInfo: nil, repeats: true)
        
        return true;
    }
    
    func stopNotifier() {
        
        reachabilityObject = nil;
        
        timer?.invalidate()
        timer = nil;
    }
    
    func timerFired(timer: NSTimer) {
        
        let currentReachabilityFlags = reachabilityFlags
        if let _previousReachabilityFlags = previousReachabilityFlags {
            if currentReachabilityFlags != previousReachabilityFlags {
                reachabilityChanged(currentReachabilityFlags)
                previousReachabilityFlags = currentReachabilityFlags
            }
        }
    }
    
    func reachabilityChanged(flags: SCNetworkReachabilityFlags) {
        if isReachableWithFlags(flags) {
            if let block = reachableBlock {
                block(self)
            }
        } else {
            if let block = unreachableBlock {
                block(self)
            }
        }
        
        // this makes sure the change notification happens on the MAIN THREAD
        dispatch_async(dispatch_get_main_queue()) {
            NSNotificationCenter.defaultCenter().postNotificationName(ReachabilityChangedNotification, object:self)
        }
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
    
    // MARK: - *** xx methods ***
    
    var currentReachabilityStatus: NetworkStatus {
        if isReachable() {
            if isReachableViaWiFi() {
                return .ReachableViaWiFi
            }
            if isRunningOnDevice {
                return .ReachableViaWWAN;
            }
        }
        
        return .NotReachable
    }
    
    private var reachabilityFlags: SCNetworkReachabilityFlags {
        var flags: SCNetworkReachabilityFlags = 0
        let gotFlags = SCNetworkReachabilityGetFlags(reachabilityRef, &flags) != 0
        if gotFlags {
            return flags
        }
        
        return 0
    }
    
    var currentReachabilityString: String {
        
        switch currentReachabilityStatus {
        case .ReachableViaWWAN:
            return NSLocalizedString("Cellular", comment: "")
        case .ReachableViaWiFi:
            return NSLocalizedString("WiFi", comment: "")
        case .NotReachable:
            return NSLocalizedString("No Connection", comment: "");
        }
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
        reachableBlock = nil
        unreachableBlock = nil
    }
}


