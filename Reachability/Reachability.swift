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

// Reachability.swift version 2.2beta2

import SystemConfiguration
import Foundation

public enum ReachabilityError: Error {
    case FailedToCreateWithAddress(sockaddr_in)
    case FailedToCreateWithHostname(String)
    case UnableToSetCallback
    case UnableToSetDispatchQueue
}

public let ReachabilityChangedNotification = "ReachabilityChangedNotification" as NSNotification.Name


func callback(reachability:SCNetworkReachability, flags: SCNetworkReachabilityFlags, info: UnsafeMutablePointer<Void>?) {

    guard let info = info else { return }
    
    let reachability = Unmanaged<Reachability>.fromOpaque(info).takeUnretainedValue()

    DispatchQueue.main.async { 
        reachability.reachabilityChanged(flags:flags)
    }
}

public class Reachability: NSObject {

    public typealias NetworkReachable = (Reachability) -> ()
    public typealias NetworkUnreachable = (Reachability) -> ()

    public enum NetworkStatus: CustomStringConvertible {

        case notReachable, reachableViaWiFi, reachableViaWWAN

        public var description: String {
            switch self {
            case .reachableViaWWAN:
                return "Cellular"
            case .reachableViaWiFi:
                return "WiFi"
            case .notReachable:
                return "No Connection"
            }
        }
    }

    public var whenReachable: NetworkReachable?
    public var whenUnreachable: NetworkUnreachable?
    public var reachableOnWWAN: Bool

    public var currentReachabilityString: String {
        return "\(currentReachabilityStatus)"
    }

    public var currentReachabilityStatus: NetworkStatus {
        guard isReachable else { return .notReachable }
        if isReachableViaWiFi {
            return .reachableViaWiFi
        }
        if isRunningOnDevice {
            return .reachableViaWWAN
        }
        
        return .notReachable
    }
    
    private var previousFlags: SCNetworkReachabilityFlags?
    
    private var isRunningOnDevice: Bool = {
        #if (arch(i386) || arch(x86_64)) && os(iOS)
            return false
        #else
            return true
        #endif
    }()
    
    private var notifierRunning = false
    private var reachabilityRef: SCNetworkReachability?
    
    private let reachabilitySerialQueue = DispatchQueue(label: "uk.co.ashleymills.reachability")
    
    required public init(reachabilityRef: SCNetworkReachability) {
        reachableOnWWAN = true
        self.reachabilityRef = reachabilityRef
    }
    
    deinit {
        stopNotifier()

        reachabilityRef = nil
        whenReachable = nil
        whenUnreachable = nil
    }
}

public extension Reachability {
    
    convenience init(hostname: String) throws {
        
        guard let ref = SCNetworkReachabilityCreateWithName(nil, hostname) else { throw ReachabilityError.FailedToCreateWithHostname(hostname) }
        
        self.init(reachabilityRef: ref)
    }
    
    class func reachabilityForInternetConnection() throws -> Reachability {
        
        var zeroAddress = sockaddr_in()
        zeroAddress.sin_len = UInt8(sizeofValue(zeroAddress))
        zeroAddress.sin_family = sa_family_t(AF_INET)
        
        guard let ref = withUnsafePointer(&zeroAddress, {
            SCNetworkReachabilityCreateWithAddress(nil, UnsafePointer($0))
        }) else { throw ReachabilityError.FailedToCreateWithAddress(zeroAddress) }
        
        return Reachability(reachabilityRef: ref)
    }
    
    // MARK: - *** Notifier methods ***
    func startNotifier() throws {
        
        guard let reachabilityRef = reachabilityRef, !notifierRunning else { return }
        
        var context = SCNetworkReachabilityContext(version: 0, info: nil, retain: nil, release: nil, copyDescription: nil)
        context.info = UnsafeMutablePointer<Void>(Unmanaged<Reachability>.passUnretained(self).toOpaque())
        
        if !SCNetworkReachabilitySetCallback(reachabilityRef, callback, &context) {
            stopNotifier()
            throw ReachabilityError.UnableToSetCallback
        }
        
        if !SCNetworkReachabilitySetDispatchQueue(reachabilityRef, reachabilitySerialQueue) {
            stopNotifier()
            throw ReachabilityError.UnableToSetDispatchQueue
        }
        
        // Perform an intial check
        reachabilitySerialQueue.async {
            let flags = self.reachabilityFlags
            self.reachabilityChanged(flags: flags)
        }
        
        notifierRunning = true
    }
    
    func stopNotifier() {
        defer { notifierRunning = false }
        guard let reachabilityRef = reachabilityRef else { return }
        
        SCNetworkReachabilitySetCallback(reachabilityRef, nil, nil)
        SCNetworkReachabilitySetDispatchQueue(reachabilityRef, nil)
    }
    
    // MARK: - *** Connection test methods ***
    var isReachable: Bool {
        let flags = reachabilityFlags
        return isReachable(flags:flags)
    }
    
    var isReachableViaWWAN: Bool {
        
        let flags = reachabilityFlags
        
        // Check we're not on the simulator, we're REACHABLE and check we're on WWAN
        return isRunningOnDevice && isReachable(flags:flags) && isOnWWAN(flags:flags)
    }
    
    var isReachableViaWiFi: Bool {
        
        let flags = reachabilityFlags
        
        // Check we're reachable
        guard isReachable(flags:flags) else { return false }
        
        // If reachable we're reachable, but not on an iOS device (i.e. simulator), we must be on WiFi
        guard isRunningOnDevice else { return true }
        
        // Check we're NOT on WWAN
        return !isOnWWAN(flags:flags)
    }
    
    override var description: String {
        
        let W = isRunningOnDevice ? (isOnWWAN(flags: reachabilityFlags) ? "W" : "-") : "X"
        let R = isReachable(flags: reachabilityFlags) ? "R" : "-"
        let c = isConnectionRequired(flags: reachabilityFlags) ? "c" : "-"
        let t = isTransientConnection(flags: reachabilityFlags) ? "t" : "-"
        let i = isInterventionRequired(flags: reachabilityFlags) ? "i" : "-"
        let C = isConnectionOnTraffic(flags: reachabilityFlags) ? "C" : "-"
        let D = isConnectionOnDemand(flags: reachabilityFlags) ? "D" : "-"
        let l = isLocalAddress(flags: reachabilityFlags) ? "l" : "-"
        let d = isDirect(flags: reachabilityFlags) ? "d" : "-"
        
        return "\(W)\(R) \(c)\(t)\(i)\(C)\(D)\(l)\(d)"
    }
}

private extension Reachability {
    
    func reachabilityChanged(flags:SCNetworkReachabilityFlags) {
        
        guard previousFlags != flags else { return }
        
        let block = isReachable(withFlags: flags) ? whenReachable : whenUnreachable
        block?(self)
        
        NotificationCenter.default.post(name: ReachabilityChangedNotification, object:self)
        
        previousFlags = flags
    }
    
    func isReachable(withFlags flags:SCNetworkReachabilityFlags) -> Bool {
        
        if !isReachable(flags: flags) {
            return false
        }
        
        if isConnectionRequiredOrTransient(flags: flags) {
            return false
        }
        
        if isRunningOnDevice {
            if isOnWWAN(flags: flags) && !reachableOnWWAN {
                // We don't want to connect when on 3G.
                return false
            }
        }
        
        return true
    }
    
    // WWAN may be available, but not active until a connection has been established.
    // WiFi may require a connection for VPN on Demand.
    func isConnectionRequired() -> Bool {
        return connectionRequired()
    }
    
    func connectionRequired() -> Bool {
        let flags = reachabilityFlags
        return isConnectionRequired(flags: flags)
    }
    
    // Dynamic, on demand connection?
    func isConnectionOnDemand() -> Bool {
        let flags = reachabilityFlags
        return isConnectionRequired(flags: flags) && isConnectionOnTrafficOrDemand(flags: flags)
    }
    
    // Is user intervention required?
    func isInterventionRequired() -> Bool {
        let flags = reachabilityFlags
        return isConnectionRequired(flags: flags) && isInterventionRequired(flags: flags)
    }
    
    func isOnWWAN(flags:SCNetworkReachabilityFlags) -> Bool {
        #if os(iOS)
            return flags.contains(.isWWAN)
        #else
            return false
        #endif
    }
    func isReachable(flags:SCNetworkReachabilityFlags) -> Bool {
        return flags.contains(.reachable)
    }
    func isConnectionRequired(flags:SCNetworkReachabilityFlags) -> Bool {
        return flags.contains(.connectionRequired)
    }
    func isInterventionRequired(flags:SCNetworkReachabilityFlags) -> Bool {
        return flags.contains(.interventionRequired)
    }
    func isConnectionOnTraffic(flags:SCNetworkReachabilityFlags) -> Bool {
        return flags.contains(.connectionOnTraffic)
    }
    func isConnectionOnDemand(flags:SCNetworkReachabilityFlags) -> Bool {
        return flags.contains(.connectionOnDemand)
    }
    func isConnectionOnTrafficOrDemand(flags:SCNetworkReachabilityFlags) -> Bool {
        return !flags.intersection([.connectionOnTraffic, .connectionOnDemand]).isEmpty
    }
    func isTransientConnection(flags:SCNetworkReachabilityFlags) -> Bool {
        return flags.contains(.transientConnection)
    }
    func isLocalAddress(flags:SCNetworkReachabilityFlags) -> Bool {
        return flags.contains(.isLocalAddress)
    }
    func isDirect(flags:SCNetworkReachabilityFlags) -> Bool {
        return flags.contains(.isDirect)
    }
    func isConnectionRequiredOrTransient(flags:SCNetworkReachabilityFlags) -> Bool {
        let testcase:SCNetworkReachabilityFlags = [.connectionRequired, .transientConnection]
        return flags.intersection(testcase) == testcase
    }
    
    var reachabilityFlags: SCNetworkReachabilityFlags {
        
        guard let reachabilityRef = reachabilityRef else { return SCNetworkReachabilityFlags() }
        
        var flags = SCNetworkReachabilityFlags()
        let gotFlags = withUnsafeMutablePointer(&flags) {
            SCNetworkReachabilityGetFlags(reachabilityRef, UnsafeMutablePointer($0))
        }
        
        if gotFlags {
            return flags
        } else {
            return SCNetworkReachabilityFlags()
        }
    }
}
