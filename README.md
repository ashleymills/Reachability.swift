Reachability.swift
==================

Replacement for Apple's Reachability re-written in Swift with callbacks

Inspired by https://github.com/tonymillion/Reachability 

NOTE:

As of Swift 1.1, you cannot convert Swift closures into C-function pointers, meaning we can't set an SCNetworkReachabilityCallBack.

To get around this, this reachability replacement uses an NSTimer firing at 1/2 second intervals.

