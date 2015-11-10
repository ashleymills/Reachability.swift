//
//  ViewController.swift
//  Reachability Sample
//
//  Created by Ashley Mills on 22/09/2014.
//  Copyright (c) 2014 Joylord Systems. All rights reserved.
//

import UIKit
import Reachability

let useClosures = false

class ViewController: UIViewController {

    @IBOutlet weak var networkStatus: UILabel!
    
    var reachability: Reachability?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        do {
            let reachability = try Reachability.reachabilityForInternetConnection()
            self.reachability = reachability
        } catch ReachabilityError.FailedToCreateWithAddress(let address) {
            networkStatus.textColor = UIColor.redColor()
            networkStatus.text = "Unable to create\nReachability with address:\n\(address)"
            return
        } catch {}
        
        if (useClosures) {
            reachability?.whenReachable = { reachability in
                self.updateLabelColourWhenReachable(reachability)
            }
            reachability?.whenUnreachable = { reachability in
                self.updateLabelColourWhenNotReachable(reachability)
            }
        } else {
            NSNotificationCenter.defaultCenter().addObserver(self, selector: "reachabilityChanged:", name: ReachabilityChangedNotification, object: reachability)
        }
        
        do {
            try reachability?.startNotifier()
        } catch {
            networkStatus.textColor = UIColor.redColor()
            networkStatus.text = "Unable to start\nnotifier"
            return
        }
    }
    
    deinit {

        reachability?.stopNotifier()
        
        if (!useClosures) {
            NSNotificationCenter.defaultCenter().removeObserver(self, name: ReachabilityChangedNotification, object: nil)
        }
    }
    
    func updateLabelColourWhenReachable(reachability: Reachability) {
        print("\(reachability.description) - \(reachability.currentReachabilityString)")
        if reachability.isReachableViaWiFi() {
            self.networkStatus.textColor = UIColor.greenColor()
        } else {
            self.networkStatus.textColor = UIColor.blueColor()
        }
        
        self.networkStatus.text = reachability.currentReachabilityString
    }

    func updateLabelColourWhenNotReachable(reachability: Reachability) {
        print("\(reachability.description) - \(reachability.currentReachabilityString)")

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


