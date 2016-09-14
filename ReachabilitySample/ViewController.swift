//
//  ViewController.swift
//  Reachability Sample
//
//  Created by Ashley Mills on 22/09/2014.
//  Copyright (c) 2014 Joylord Systems. All rights reserved.
//

import UIKit
import Reachability

class ViewController: UIViewController {

    @IBOutlet weak var networkStatus: UILabel!
    @IBOutlet weak var hostNameLabel: UILabel!
    
    var reachability: Reachability?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Start reachability without a hostname intially
        setupReachability(nil, useClosures: true)
        startNotifier()

        // After 5 seconds, stop and re-start reachability, this time using a hostname
        let dispatchTime = DispatchTime.now() + DispatchTimeInterval.seconds(5)
        DispatchQueue.main.asyncAfter(deadline: dispatchTime) {
            self.stopNotifier()
            self.setupReachability("google.com", useClosures: true)
            self.startNotifier()

            let dispatchTime = DispatchTime.now() + DispatchTimeInterval.seconds(5)
            DispatchQueue.main.asyncAfter(deadline: dispatchTime) {
                self.stopNotifier()
                self.setupReachability("invalidhost", useClosures: true)
                self.startNotifier()            }

        }
    }
    
    func setupReachability(_ hostName: String?, useClosures: Bool) {
        hostNameLabel.text = hostName != nil ? hostName : "No host name"
        
        print("--- set up with host name: \(hostNameLabel.text!)")

        let reachability = hostName == nil ? Reachability() : Reachability(hostname: hostName!)
        self.reachability = reachability
        
        if useClosures {
            reachability?.whenReachable = { reachability in
                DispatchQueue.main.async {
                    self.updateLabelColourWhenReachable(reachability)
                }
            }
            reachability?.whenUnreachable = { reachability in
                DispatchQueue.main.async {
                    self.updateLabelColourWhenNotReachable(reachability)
                }
            }
        } else {
            NotificationCenter.default.addObserver(self, selector: #selector(ViewController.reachabilityChanged(_:)), name: ReachabilityChangedNotification, object: reachability)
        }
    }
    
    func startNotifier() {
        print("--- start notifier")
        do {
            try reachability?.startNotifier()
        } catch {
            networkStatus.textColor = .red
            networkStatus.text = "Unable to start\nnotifier"
            return
        }
    }
    
    func stopNotifier() {
        print("--- stop notifier")
        reachability?.stopNotifier()
        NotificationCenter.default.removeObserver(self, name: ReachabilityChangedNotification, object: nil)
        reachability = nil
    }
    
    func updateLabelColourWhenReachable(_ reachability: Reachability) {
        print("\(reachability.description) - \(reachability.currentReachabilityString)")
        if reachability.isReachableViaWiFi {
            self.networkStatus.textColor = .green
        } else {
            self.networkStatus.textColor = .blue
        }
        
        self.networkStatus.text = reachability.currentReachabilityString
    }

    func updateLabelColourWhenNotReachable(_ reachability: Reachability) {
        print("\(reachability.description) - \(reachability.currentReachabilityString)")

        self.networkStatus.textColor = .red
        
        self.networkStatus.text = reachability.currentReachabilityString
    }

    
    func reachabilityChanged(_ note: Notification) {
        let reachability = note.object as! Reachability
        
        if reachability.isReachable {
            updateLabelColourWhenReachable(reachability)
        } else {
            updateLabelColourWhenNotReachable(reachability)
        }
    }
    
    deinit {
        stopNotifier()
    }

}


