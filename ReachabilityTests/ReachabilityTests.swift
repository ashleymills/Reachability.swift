//
//  ReachabilityTests.swift
//  ReachabilityTests
//
//  Created by Ashley Mills on 23/11/2015.
//  Copyright © 2015 Ashley Mills. All rights reserved.
//

import XCTest
@testable import Reachability

class ReachabilityTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func testValidHost() {
        
        // Testing with an invalid host will initially show as UNreachable, but then the callback
        // gets fired a second time reporting the host as reachable
        
    
        let validHostName = "google.com"
        
        guard let reachability = Reachability(hostname: validHostName) else {
            XCTAssert(false, "Unable to create reachability")
            return
        }
        
        let expected = expectation(description: "Check valid host")
        reachability.whenReachable = { reachability in
            DispatchQueue.main.async {
                print("Pass: \(validHostName) is reachable - \(reachability)")
                
                // Only fulfill the expectation on host reachable
                expected.fulfill()
            }
        }
        reachability.whenUnreachable = { reachability in
            DispatchQueue.main.async {
                print("\(validHostName) is initially unreachable - \(reachability)")
                // Expectation isn't fulfilled here, so wait will time out if this is the only closure called
            }
        }
        
        do {
            try reachability.startNotifier()
        } catch {
            XCTAssert(false, "Unable to start notifier")
            return
        }
        
        waitForExpectations(timeout: 5, handler: nil)
        
        reachability.stopNotifier()
    }

    func testInvalidHost() {
        let invalidHostName = "invalidhost"

        guard let reachability = Reachability(hostname: invalidHostName) else {
            XCTAssert(false, "Unable to create reachability")
            return
        }
        
        let expected = expectation(description: "Check invalid host")
        reachability.whenReachable = { reachability in
            DispatchQueue.main.async {
                XCTAssert(false, "\(invalidHostName) should never be reachable - \(reachability))")
            }
        }
        
        reachability.whenUnreachable = { reachability in
            DispatchQueue.main.async {
                print("Pass: \(invalidHostName) is unreachable - \(reachability))")
                expected.fulfill()
            }
        }
        
        do {
            try reachability.startNotifier()
        } catch {
            XCTAssert(false, "Unable to start notifier")
            return
        }
        
        waitForExpectations(timeout: 5, handler: nil)
        
        reachability.stopNotifier()
    }
    
}
