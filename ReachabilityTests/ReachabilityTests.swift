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
    
    func testInvalidHost() {
        
        let reachability: Reachability
        let invalidHostName = "google.com"

        do {
            try reachability = Reachability(hostname: invalidHostName)
        } catch {
            XCTAssert(false, "Unable to create reachability")
            return
        }
        
        let expectation = expectationWithDescription("Check invalid host")
        reachability.whenReachable = { reachability in
            dispatch_async(dispatch_get_main_queue()) {
                XCTAssert(false, "\(invalidHostName) should be unreachable - \(reachability)")
                expectation.fulfill()
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
    
    func testaValidHost() {
        
        let reachability: Reachability
        let validHostName = "google.com"
        
        do {
            try reachability = Reachability(hostname: validHostName)
        } catch {
            XCTAssert(false, "Unable to create reachability")
            return
        }
        
        let expectation = expectationWithDescription("Check invalid host")
        reachability.whenReachable = { reachability in
            dispatch_async(dispatch_get_main_queue()) {
                print("Pass: \(validHostName) is reachable - \(reachability)")
                expectation.fulfill()
            }
        }
        reachability.whenUnreachable = { reachability in
            dispatch_async(dispatch_get_main_queue()) {
                XCTAssert(false, "\(validHostName) should be reachable - \(reachability)")
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
