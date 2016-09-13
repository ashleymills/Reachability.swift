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
    view.layer?.backgroundColor = NSColor.whiteColor().CGColor

    // Start reachability without a hostname intially
    setupReachability(useHostName: false, useClosures: true)
    startNotifier()

    // After 5 seconds, stop and re-start reachability, this time using a hostname
    let dispatchTime = dispatch_time(DISPATCH_TIME_NOW, Int64(UInt64(5) * NSEC_PER_SEC))
    dispatch_after(dispatchTime, dispatch_get_main_queue()) {
      self.stopNotifier()
      self.setupReachability(useHostName: true, useClosures: true)
      self.startNotifier()
    }
  }

  func setupReachability(useHostName useHostName: Bool, useClosures: Bool) {
    let hostName = "google.com"
    hostNameLabel.stringValue = useHostName ? hostName : "No host name"

    print("--- set up with host name: \(hostNameLabel.stringValue)")

    do {
      let reachability = try useHostName ? Reachability(hostname: hostName) : Reachability.reachabilityForInternetConnection()
      self.reachability = reachability
    } catch ReachabilityError.FailedToCreateWithAddress(let address) {
      networkStatus.textColor = NSColor.redColor()
      networkStatus.stringValue = "Unable to create\nReachability with address:\n\(address)"
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
      NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(ViewController.reachabilityChanged(_:)), name: ReachabilityChangedNotification, object: reachability)
    }
  }

  func startNotifier() {
    print("--- start notifier")
    do {
      try reachability?.startNotifier()
    } catch {
      networkStatus.textColor = NSColor.redColor()
      networkStatus.stringValue = "Unable to start\nnotifier"
      return
    }
  }

  func stopNotifier() {
    print("--- stop notifier")
    reachability?.stopNotifier()
    NSNotificationCenter.defaultCenter().removeObserver(self, name: ReachabilityChangedNotification, object: nil)
    reachability = nil
  }

  func updateLabelColourWhenReachable(reachability: Reachability) {
    print("\(reachability.description) - \(reachability.currentReachabilityString)")
    if reachability.isReachableViaWiFi() {
      self.networkStatus.textColor = NSColor.greenColor()
    } else {
      self.networkStatus.textColor = NSColor.blueColor()
    }

    self.networkStatus.stringValue = reachability.currentReachabilityString
  }

  func updateLabelColourWhenNotReachable(reachability: Reachability) {
    print("\(reachability.description) - \(reachability.currentReachabilityString)")

    self.networkStatus.textColor = NSColor.redColor()

    self.networkStatus.stringValue = reachability.currentReachabilityString
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
