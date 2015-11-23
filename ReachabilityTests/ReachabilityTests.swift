//
//  ReachabilityTests.swift
//  ReachabilityTests
//
//  Created by Ashley Mills on 23/11/2015.
//  Copyright © 2015 Ashley Mills. All rights reserved.
//

import XCTest
import Reachability

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
        
        let reachability: Reachability
        let validHostName = "google.com"
        
        do {
            try reachability = Reachability(hostname: validHostName)
        } catch {
            XCTAssert(false, "Unable to create reachability")
            return
        }
        
        let expectation = expectationWithDescription("Check valid host")
        reachability.whenReachable = { reachability in
            dispatch_async(dispatch_get_main_queue()) {
                print("Pass: \(validHostName) is reachable - \(reachability)")
                
                // Only fulfill the expectaion on host reachable
                expectation.fulfill()
            }
        }
        reachability.whenUnreachable = { reachability in
            dispatch_async(dispatch_get_main_queue()) {
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
        
        waitForExpectationsWithTimeout(5, handler: nil)
        
        reachability.stopNotifier()
    }

    func testInvalidHost() {
        
        let reachability: Reachability
        let invalidHostName = "invalidhost"

        do {
            try reachability = Reachability(hostname: invalidHostName)
        } catch {
            XCTAssert(false, "Unable to create reachability")
            return
        }
        
        let expectation = expectationWithDescription("Check invalid host")
        reachability.whenReachable = { reachability in
            dispatch_async(dispatch_get_main_queue()) {
                XCTAssert(false, "\(invalidHostName) should never be reachable - \(reachability))")
            }
        }
        
        reachability.whenUnreachable = { reachability in
            dispatch_async(dispatch_get_main_queue()) {
                print("Pass: \(invalidHostName) is unreachable - \(reachability))")
                expectation.fulfill()
            }
        }
        
        do {
            try reachability.startNotifier()
        } catch {
            XCTAssert(false, "Unable to start notifier")
            return
        }
        
        waitForExpectationsWithTimeout(5, handler: nil)
        
        reachability.stopNotifier()
    }
    
}
