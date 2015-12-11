# Reachability.swift

Reachability.swift is a replacement for Apple's Reachability sample, re-written in Swift with closures.

It is compatible with **iOS** (8.0 - 9.2), **OSX** (10.9 - 10.11) and **tvOS** (9.0 - 9.1)

Inspired by https://github.com/tonymillion/Reachability

## Supporting **Reachability.swift**
Keeping **Reachability.swift** up-to-date is a time consuming task. Making updates, reviewing pull requests, responding to issues and answering emails all take time. If you'd like to help keep me motivated, please download my free app, [Foto Flipper] from the App Store. (To really motivate me, pay $0.99 for the IAP!)

And don't forget to **★** the repo. This increases its visibility and encourages others to contribute.

Thanks
Ash

## Installation
### Manual
Just drop the **Reachability.swift** file into your project. That's it!

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

### Carthage
[Carthage][] is a decentralized dependency manager that builds your dependencies and provides you with binary frameworks.
To install Reachability.swift with Carthage:

1. Install Carthage via [Homebrew][]
  ```bash
  $ brew update
  $ brew install carthage
  ```

2. Add `github "ashleymills/Reachability.swift"` to your Cartfile.

3. Run `carthage update`.

4. Drag `Reachability.framework` from the `Carthage/Build/iOS/` directory to the `Linked Frameworks and Libraries` section of your Xcode project’s `General` settings.

5. Add `$(SRCROOT)/Carthage/Build/iOS/Reachability.framework` to `Input Files` of Run Script Phase for Carthage.

[Carthage]: https://github.com/Carthage/Carthage
[Homebrew]: http://brew.sh
[Foto Flipper]: http://itunes.com/apps/fotoflipper

## Example - closures

```swift
let reachability: Reachability
do {
    reachability = try Reachability.reachabilityForInternetConnection()
} catch {
    print("Unable to create Reachability")
    return
}


reachability.whenReachable = { reachability in
    // this is called on a background thread, but UI updates must
    // be on the main thread, like this:
    dispatch_async(dispatch_get_main_queue()) {
        if reachability.isReachableViaWiFi() {
            print("Reachable via WiFi")
        } else {
            print("Reachable via Cellular")
        }
    }
}
reachability.whenUnreachable = { reachability in
    // this is called on a background thread, but UI updates must
    // be on the main thread, like this:
    dispatch_async(dispatch_get_main_queue()) {
        print("Not reachable")
    }
}

do {
    try reachability.startNotifier()
} catch {
    print("Unable to start notifier")
}
```

and for stopping notifications

```swift
reachability.stopNotifier()
```

## Example - notifications

This sample will use `NSNotification`s to notify when the interface has changed. They will be delivered on the **MAIN THREAD**, so you *can* do UI updates from within the function.

```swift
let reachability: Reachability
do {
    reachability = try Reachability.reachabilityForInternetConnection()
} catch {
    print("Unable to create Reachability")
    return
}

NSNotificationCenter.defaultCenter().addObserver(self,
                                                 selector: "reachabilityChanged:",
                                                 name: ReachabilityChangedNotification,
                                                 object: reachability)

reachability.startNotifier()
```

and

```swift
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
```

and for stopping notifications

```swift
reachability.stopNotifier()
NSNotificationCenter.defaultCenter().removeObserver(self,
                                                    name: ReachabilityChangedNotification,
                                                    object: reachability)
```

## Want to help?

Got a bug fix, or a new feature? Create a pull request and go for it!

## Let me know!

If you use **Reachability.swift**, please let me know about your app and I'll put a link [here…](https://github.com/ashleymills/Reachability.swift/wiki/Apps-using-Reachability.swift) and tell your friends!

Cheers,
Ash
