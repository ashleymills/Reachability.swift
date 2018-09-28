//
//  ViewController.swift
//  ReachabilityMacSample
//
//  Created by Reda Lemeden on 28/11/2015.
//  Copyright © 2015 Ashley Mills. All rights reserved.
//

import Cocoa
import Reachability

class ViewController: NSViewController {
    @IBOutlet weak var networkStatus: NSTextField!
    @IBOutlet weak var hostNameLabel: NSTextField!
    
    var reachability: Reachability?
    let hostNames = [nil, "google.com", "invalidhost"]
    var hostIndex = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.wantsLayer = true
        
        startHost(at: 0)
    }
    
    func startHost(at index: Int) {
        stopNotifier()
        setupReachability(hostNames[index], useClosures: true)
        startNotifier()
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            self.startHost(at: (index + 1) % 3)
        }
    }

    func setupReachability(_ hostName: String?, useClosures: Bool) {
        let reachability: Reachability?
        if let hostName = hostName {
            reachability = Reachability(hostname: hostName)
            hostNameLabel.stringValue = hostName
        } else {
            reachability = Reachability()
            hostNameLabel.stringValue = "No host name"
        }
        self.reachability = reachability
        print("--- set up with host name: \(hostNameLabel.stringValue)")

        if useClosures {
            reachability?.whenReachable = { reachability in
                self.updateLabelColourWhenReachable(reachability)
            }
            reachability?.whenUnreachable = { reachability in
                self.updateLabelColourWhenNotReachable(reachability)
            }
        } else {
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(ViewController.reachabilityChanged(_:)),
                name: .reachabilityChanged,
                object: reachability
            )
        }
    }
    
    func startNotifier() {
        print("--- start notifier")
        do {
            try reachability?.startNotifier()
        } catch {
            networkStatus.textColor = .red
            networkStatus.stringValue = "Unable to start\nnotifier"
            return
        }
    }
    
    func stopNotifier() {
        print("--- stop notifier")
        reachability?.stopNotifier()
        NotificationCenter.default.removeObserver(self, name: .reachabilityChanged, object: nil)
        reachability = nil
    }
    
    func updateLabelColourWhenReachable(_ reachability: Reachability) {
        print("\(reachability.description) - \(reachability.connection.description)")
        if reachability.connection == .wifi {
            self.networkStatus.textColor = .green
        } else {
            self.networkStatus.textColor = .blue
        }
        
        self.networkStatus.stringValue = "\(reachability.connection)"
    }
    
    func updateLabelColourWhenNotReachable(_ reachability: Reachability) {
        print("\(reachability.description) - \(reachability.connection)")
        
        self.networkStatus.textColor = .red
        
        self.networkStatus.stringValue = "\(reachability.connection)"
    }
    
    @objc func reachabilityChanged(_ note: Notification) {
        let reachability = note.object as! Reachability
        
        if reachability.connection != .none {
            updateLabelColourWhenReachable(reachability)
        } else {
            updateLabelColourWhenNotReachable(reachability)
        }
    }
}
