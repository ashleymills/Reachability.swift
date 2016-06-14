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

public enum ReachabilityError: ErrorProtocol {
    case FailedToCreateWithAddress(sockaddr_in)
    case FailedToCreateWithHostname(String)
    case UnableToSetCallback
    case UnableToSetDispatchQueue
}

public let ReachabilityChangedNotification = "ReachabilityChangedNotification" as NSNotification.Name


func callback(reachability:SCNetworkReachability, flags: SCNetworkReachabilityFlags, info: UnsafeMutablePointer<Void>?) {

    guard let info = info else { return }
    
    let reachability = Unmanaged<Reachability>.fromOpaque(OpaquePointer(info)).takeUnretainedValue()

    DispatchQueue.main.async { 
        reachability.reachabilityChanged(flags:flags)
    }
}

public class Reachability: NSObject {

    public typealias NetworkReachable = (Reachability) -> ()
    public typealias NetworkUnreachable = (Reachability) -> ()

    public enum NetworkStatus: CustomStringConvertible {

        case NotReachable, ReachableViaWiFi, ReachableViaWWAN

        public var description: String {
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
    public var whenReachable: NetworkReachable?
    public var whenUnreachable: NetworkUnreachable?
    public var reachableOnWWAN: Bool
    public var notificationCenter = NotificationCenter.default()

    public var currentReachabilityStatus: NetworkStatus {
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

    public var currentReachabilityString: String {
        return "\(currentReachabilityStatus)"
    }

    private var previousFlags: SCNetworkReachabilityFlags?
    
    // MARK: - *** Initialisation methods ***
    
    required public init(reachabilityRef: SCNetworkReachability) {
        reachableOnWWAN = true
        self.reachabilityRef = reachabilityRef
    }
    
    public convenience init(hostname: String) throws {
        
        guard let nodename = (hostname as NSString).utf8String,
            ref = SCNetworkReachabilityCreateWithName(nil, nodename) else { throw ReachabilityError.FailedToCreateWithHostname(hostname) }

        self.init(reachabilityRef: ref)
    }

    public class func reachabilityForInternetConnection() throws -> Reachability {
        
        var zeroAddress = sockaddr_in()
        zeroAddress.sin_len = UInt8(sizeofValue(zeroAddress))
        zeroAddress.sin_family = sa_family_t(AF_INET)
        
        guard let ref = withUnsafePointer(&zeroAddress, {
            SCNetworkReachabilityCreateWithAddress(nil, UnsafePointer($0))
        }) else { throw ReachabilityError.FailedToCreateWithAddress(zeroAddress) }
        
        return Reachability(reachabilityRef: ref)
    }

    public class func reachabilityForLocalWiFi() throws -> Reachability {

        var localWifiAddress: sockaddr_in = sockaddr_in(sin_len: __uint8_t(0), sin_family: sa_family_t(0), sin_port: in_port_t(0), sin_addr: in_addr(s_addr: 0), sin_zero: (0, 0, 0, 0, 0, 0, 0, 0))
        localWifiAddress.sin_len = UInt8(sizeofValue(localWifiAddress))
        localWifiAddress.sin_family = sa_family_t(AF_INET)

        // IN_LINKLOCALNETNUM is defined in <netinet/in.h> as 169.254.0.0
        let address: UInt32 = 0xA9FE0000
        localWifiAddress.sin_addr.s_addr = in_addr_t(address.bigEndian)

        guard let ref = withUnsafePointer(&localWifiAddress, {
            SCNetworkReachabilityCreateWithAddress(nil, UnsafePointer($0))
        }) else { throw ReachabilityError.FailedToCreateWithAddress(localWifiAddress) }
        
        return Reachability(reachabilityRef: ref)
    }

    // MARK: - *** Notifier methods ***
    public func startNotifier() throws {

        guard let reachabilityRef = reachabilityRef where !notifierRunning else { return }
        
        var context = SCNetworkReachabilityContext(version: 0, info: nil, retain: nil, release: nil, copyDescription: nil)
        context.info = UnsafeMutablePointer<Void>(OpaquePointer(bitPattern: Unmanaged<Reachability>.passUnretained(self)))
        
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

    public func stopNotifier() {
        defer { notifierRunning = false }
        guard let reachabilityRef = reachabilityRef else { return }

        SCNetworkReachabilitySetCallback(reachabilityRef, nil, nil)
        SCNetworkReachabilitySetDispatchQueue(reachabilityRef, nil)
    }
    
    // MARK: - *** Connection test methods ***
    public func isReachable() -> Bool {
        let flags = reachabilityFlags
        return isReachableWithFlags(flags:flags)
    }

    public func isReachableViaWWAN() -> Bool {
        
        let flags = reachabilityFlags
        
        // Check we're not on the simulator, we're REACHABLE and check we're on WWAN
        return isRunningOnDevice && isReachable(flags:flags) && isOnWWAN(flags:flags)
    }

    public func isReachableViaWiFi() -> Bool {
        
        let flags = reachabilityFlags
        
        // Check we're reachable
        if !isReachable(flags:flags) {
            return false
        }
        
        // Must be on WiFi if reachable but not on an iOS device (i.e. simulator)
        if !isRunningOnDevice {
            return true
        }
        
        // Check we're NOT on WWAN
        return !isOnWWAN(flags:flags)
    }

    // MARK: - *** Private methods ***
    private var isRunningOnDevice: Bool = {
        #if (arch(i386) || arch(x86_64)) && os(iOS)
            return false
        #else
            return true
        #endif
    }()

    private var notifierRunning = false
    private var reachabilityRef: SCNetworkReachability?
    
    private let reachabilitySerialQueue = DispatchQueue(label: "uk.co.ashleymills.reachability", attributes: .serial, target: nil)

    private func reachabilityChanged(flags:SCNetworkReachabilityFlags) {
        
        guard previousFlags != flags else { return }
        
        if isReachableWithFlags(flags:flags) {
            if let block = whenReachable {
                block(self)
            }
        } else {
            if let block = whenUnreachable {
                block(self)
            }
        }

        notificationCenter.post(name: ReachabilityChangedNotification, object:self)

        previousFlags = flags
    }

    private func isReachableWithFlags(flags:SCNetworkReachabilityFlags) -> Bool {

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
    private func isConnectionRequired() -> Bool {
        return connectionRequired()
    }

    private func connectionRequired() -> Bool {
        let flags = reachabilityFlags
        return isConnectionRequired(flags: flags)
    }

    // Dynamic, on demand connection?
    private func isConnectionOnDemand() -> Bool {
        let flags = reachabilityFlags
        return isConnectionRequired(flags: flags) && isConnectionOnTrafficOrDemand(flags: flags)
    }

    // Is user intervention required?
    private func isInterventionRequired() -> Bool {
        let flags = reachabilityFlags
        return isConnectionRequired(flags: flags) && isInterventionRequired(flags: flags)
    }

    private func isOnWWAN(flags:SCNetworkReachabilityFlags) -> Bool {
        #if os(iOS)
            return flags.contains(.iswwan)
        #else
            return false
        #endif
    }
    private func isReachable(flags:SCNetworkReachabilityFlags) -> Bool {
        return flags.contains(.reachable)
    }
    private func isConnectionRequired(flags:SCNetworkReachabilityFlags) -> Bool {
        return flags.contains(.connectionRequired)
    }
    private func isInterventionRequired(flags:SCNetworkReachabilityFlags) -> Bool {
        return flags.contains(.interventionRequired)
    }
    private func isConnectionOnTraffic(flags:SCNetworkReachabilityFlags) -> Bool {
        return flags.contains(.connectionOnTraffic)
    }
    private func isConnectionOnDemand(flags:SCNetworkReachabilityFlags) -> Bool {
        return flags.contains(.connectionOnDemand)
    }
    func isConnectionOnTrafficOrDemand(flags:SCNetworkReachabilityFlags) -> Bool {
        return !flags.intersection([.connectionOnTraffic, .connectionOnDemand]).isEmpty
    }
    private func isTransientConnection(flags:SCNetworkReachabilityFlags) -> Bool {
        return flags.contains(.transientConnection)
    }
    private func isLocalAddress(flags:SCNetworkReachabilityFlags) -> Bool {
        return flags.contains(.isLocalAddress)
    }
    private func isDirect(flags:SCNetworkReachabilityFlags) -> Bool {
        return flags.contains(.isDirect)
    }
    private func isConnectionRequiredOrTransient(flags:SCNetworkReachabilityFlags) -> Bool {
        let testcase:SCNetworkReachabilityFlags = [.connectionRequired, .transientConnection]
        return flags.intersection(testcase) == testcase
    }

    private var reachabilityFlags: SCNetworkReachabilityFlags {
        
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

    override public var description: String {

        var W: String
        if isRunningOnDevice {
            W = isOnWWAN(flags: reachabilityFlags) ? "W" : "-"
        } else {
            W = "X"
        }
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

    deinit {
        stopNotifier()

        reachabilityRef = nil
        whenReachable = nil
        whenUnreachable = nil
    }
}
