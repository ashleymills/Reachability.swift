# Reachability.swift

Replacement for Apple's Reachability re-written in Swift with closures

Inspired by https://github.com/tonymillion/Reachability 

**NOTES:**

- If an application has the privacy option “Use cellular data” turned off, the Reachability class still reports isReachable() to be true. There is currently no (non-private) API to detect this. If you need this feature, please raise file a [bug report](https://bugreport.apple.com) with Apple to get this fixed. See devforums thread for details: https://devforums.apple.com/message/1059332#1059332

## Installation
### CocoaPods
[CocoaPods][] is a dependency manager for Cocoa projects. To install Reachability.swift with CocoaPods:

 1. Make sure CocoaPods is [installed][CocoaPods Installation].

 2. Update your Podfile to include the following:

    ``` ruby
    use_frameworks!
    pod 'ReachabilitySwift', git: 'https://github.com/ashleymills/Reachability.swift'
    ```

 3. Run `pod install`.

[CocoaPods]: https://cocoapods.org
[CocoaPods Installation]: https://guides.cocoapods.org/using/getting-started.html#getting-started

### Manual
Just drop the **Reachability.swift** file into your project. That's it!

## Example - closures

````
    let reachability = Reachability.reachabilityForInternetConnection()

    reachability?.whenReachable = { reachability in
        // keep in mind this is called on a background thread
        // and if you are updating the UI it needs to happen
        // on the main thread, like this:
        dispatch_async(dispatch_get_main_queue()) {
            if reachability.isReachableViaWiFi() {
                print("Reachable via WiFi")
            } else {
                print("Reachable via Cellular")
            }
        }
    }
    reachability?.whenUnreachable = { reachability in
        // keep in mind this is called on a background thread
        // and if you are updating the UI it needs to happen
        // on the main thread, like this:
        dispatch_async(dispatch_get_main_queue()) {
            print("Not reachable")
        }
    }

    reachability?.startNotifier()
````

and for stopping notifications

````
reachability?.stopNotifier()
````

## Example - notifications

This sample will use `NSNotification`s to notify when the interface has changed. They will be delivered on the **MAIN THREAD**, so you *can* do UI updates from within the function.

````
    let reachability = Reachability.reachabilityForInternetConnection()

    NSNotificationCenter.defaultCenter().addObserver(self, 
                                                     selector: "reachabilityChanged:", 
                                                     name: ReachabilityChangedNotification, 
                                                     object: reachability)
    
    reachability?.startNotifier()
````

and

````
    func reachabilityChanged(note: NSNotification) {

        let reachability = note.object as! Reachability

        if reachability.isReachable() {
            if reachability.isReachableViaWiFi() {
                print("Reachable via WiFi")
            } else {
                print("Reachable via Cellular")
            }
        } else {
            print("Not reachable")
        }
    }
````

and for stopping notifications

````
reachability.stopNotifier()
NSNotificationCenter.defaultCenter().removeObserver(self, 
                                                    name: ReachabilityChangedNotification, 
                                                    object: reachability)
````

## Want to help?

Got a bug fix, or a new feature? Create a pull request and go for it!

## Let me know!

If you use **Reachability.swift**, please let me know about your app and I'll put a link [here…](https://github.com/ashleymills/Reachability.swift/wiki/Apps-using-Reachability.swift) and tell your friends! 

Cheers,
Ash

