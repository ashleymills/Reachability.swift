//
//  Reachable.swift
//  Reachability
//
//  Created by Thomas Léger on 27/09/2017.
//  Copyright © 2017 Ashley Mills. All rights reserved.
//

protocol ReachabilityProtocol {
	var whenReachable: Reachability.NetworkReachable? { get }
	var whenUnreachable: Reachability.NetworkUnreachable? { get }
	var reachableOnWWAN: Bool { get }
	var allowsCellularConnection: Bool { get }
	var connection: Reachability.Connection { get }

	var description: String { get }
	
	func startNotifier() throws
	func stopNotifier()
}
