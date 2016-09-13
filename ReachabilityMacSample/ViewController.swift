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

  override func viewDidLoad() {
    super.viewDidLoad()
    view.wantsLayer = true

    // Start reachability without a hostname intially
    setupReachability(useHostName: false, useClosures: true)
    startNotifier()

    // After 5 seconds, stop and re-start reachability, this time using a hostname
    let dispatchTime = DispatchTime.now() + Double(Int64(UInt64(5) * NSEC_PER_SEC)) / Double(NSEC_PER_SEC)
    DispatchQueue.main.asyncAfter(deadline: dispatchTime) {
      self.stopNotifier()
      self.setupReachability(useHostName: true, useClosures: true)
      self.startNotifier()
    }
  }

  func setupReachability(useHostName: Bool, useClosures: Bool) {
    let hostName = "google.com"
    hostNameLabel.stringValue = useHostName ? hostName : "No host name"

    print("--- set up with host name: \(hostNameLabel.stringValue)")

    let reachability = useHostName ? Reachability(hostname: hostName) : Reachability()
    self.reachability = reachability

    if useClosures {
      reachability?.whenReachable = { reachability in
        self.updateLabelColourWhenReachable(reachability)
      }
      reachability?.whenUnreachable = { reachability in
        self.updateLabelColourWhenNotReachable(reachability)
      }
    } else {
<<<<<<< HEAD
      NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(ViewController.reachabilityChanged(_:)), name: ReachabilityChangedNotification, object: reachability)
=======
      NotificationCenter.default.addObserver(self, selector: #selector(ViewController.reachabilityChanged(_:)), name: ReachabilityChangedNotification, object: reachability)
>>>>>>> feature/ios10
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

    self.networkStatus.stringValue = reachability.currentReachabilityString
  }

  func updateLabelColourWhenNotReachable(_ reachability: Reachability) {
    print("\(reachability.description) - \(reachability.currentReachabilityString)")

    self.networkStatus.textColor = .red

    self.networkStatus.stringValue = reachability.currentReachabilityString
  }

  func reachabilityChanged(_ note: Notification) {
    let reachability = note.object as! Reachability

    if reachability.isReachable {
      updateLabelColourWhenReachable(reachability)
    } else {
      updateLabelColourWhenNotReachable(reachability)
    }
  }
}
