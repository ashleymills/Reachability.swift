//
//  ViewController.swift
//  Reachability Sample
//
//  Created by Ashley Mills on 22/09/2014.
//  Copyright (c) 2014 Joylord Systems. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    @IBOutlet weak var networkStatus: UILabel!
    
    let reachability = Reachability.reachabilityForInternetConnection()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        reachability.reachableBlock = { reachability in
            self.updateLabelColourWhenReachable(reachability)
        }
        reachability.unreachableBlock = { reachability in
            self.updateLabelColourWhenNotReachable(reachability)
        }
        
        reachability.startNotifier()
        
        if reachability.isReachable() {
            updateLabelColourWhenReachable(reachability)
        } else {
            updateLabelColourWhenNotReachable(reachability)
        }
    }
    
    deinit {
        reachability.stopNotifier()
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

}


