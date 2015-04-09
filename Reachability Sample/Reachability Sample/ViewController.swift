//
//  ViewController.swift
//  Reachability Sample
//
//  Created by Ashley Mills on 22/09/2014.
//  Copyright (c) 2014 Joylord Systems. All rights reserved.
//

import UIKit

let useClosures = false

class ViewController: UIViewController {

    @IBOutlet weak var networkStatus: UILabel!
    
    let reachability = Reachability.reachabilityForInternetConnection()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        if (useClosures) {
            reachability.whenReachable = { reachability in
                self.updateLabelColourWhenReachable(reachability)
            }
            reachability.whenUnreachable = { reachability in
                self.updateLabelColourWhenNotReachable(reachability)
            }
        } else {
            NSNotificationCenter.defaultCenter().addObserver(self, selector: "reachabilityChanged:", name: ReachabilityChangedNotification, object: reachability)
        }
        
        reachability.startNotifier()
        
        // Initial reachability check
        if reachability.isReachable() {
            updateLabelColourWhenReachable(reachability)
        } else {
            updateLabelColourWhenNotReachable(reachability)
        }
    }
    
    deinit {

        reachability.stopNotifier()
        
        if (!useClosures) {
            NSNotificationCenter.defaultCenter().removeObserver(self, name: ReachabilityChangedNotification, object: nil)
        }
    }
    
    func updateLabelColourWhenReachable(reachability: Reachability) {
        if reachability.isReachableViaWiFi() {
            self.networkStatus.textColor = UIColor.greenColor()
        } else {
            self.networkStatus.textColor = UIColor.blueColor()
        }
        
        self.networkStatus.text = reachability.currentReachabilityString
    }

    func updateLabelColourWhenNotReachable(reachability: Reachability) {
        self.networkStatus.textColor = UIColor.redColor()
        
        self.networkStatus.text = reachability.currentReachabilityString
    }

    
    func reachabilityChanged(note: NSNotification) {
        let reachability = note.object as! Reachability
        
        if reachability.isReachable() {
            updateLabelColourWhenReachable(reachability)
        } else {
            updateLabelColourWhenNotReachable(reachability)
        }
    }
}


