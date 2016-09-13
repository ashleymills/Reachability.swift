# Reachability.swift

Reachability.swift is a replacement for Apple's Reachability sample, re-written in Swift with closures.

It is compatible with **iOS** (8.0 - 10.0), **OSX** (10.9 - 10.12) and **tvOS** (9.0 - 10.0)

Inspired by https://github.com/tonymillion/Reachability

#IMPORTANT

##Supporting Swift 2.3 and Swift 3

The source has been updated to support both Swift 2.3 (tag v2.4) and Swift 3 (tag v3.0)  

To install **Reachability.swift** for Swift 2.3 using CocoaPods, include the following in your Podfile
```
pod 'ReachabilitySwift', '~> 2.4'
```

To install **Reachability.swift** for Swift 3.x using CocoaPods, include the following in your Podfile
```
pod 'ReachabilitySwift', '~> 3'
```
##Swift 3 / Breaking changes#

The following iOS 10 branch contains the following breaking changes:

Previously:
```swift
class func reachabilityForInternetConnection() throws
```
Now: 
```swift
init?()
```

Previously: 
```swift
init(hostname: String) throws
```
Now:
```swift
init?(hostname: String)
```

Previously:
```swift
public enum NetworkStatus: CustomStringConvertible {
    case NotReachable, ReachableViaWiFi, ReachableViaWWAN
}
```
Now:
```swift
public enum NetworkStatus: CustomStringConvertible {
    case notReachable, reachableViaWiFi, reachableViaWWAN
}
```



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
    pod 'ReachabilitySwift'
    ```

 3. Run `pod install`.

[CocoaPods]: https://cocoapods.org
[CocoaPods Installation]: https://guides.cocoapods.org/using/getting-started.html#getting-started
 
 4. In your code import Reachability like so:
   `import ReachabilitySwift`

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
//declare this property where it won't go out of scope relative to your listener
let reachability = Reachability()!

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
//declare this property where it won't go out of scope relative to your listener
let reachability = Reachability()!

//declare this inside of viewWillAppear

    NSNotificationCenter.defaultCenter().addObserver(self, selector: "reachabilityChanged:",name: ReachabilityChangedNotification,object: reachability)
    do{
      try reachability.startNotifier()
    }catch{
      print("could not start reachability notifier")
    }
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
    print("Network not reachable")
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

## Got a problem?

Please read https://github.com/ashleymills/Reachability.swift/wiki/Raising-an-issue before raising an issue.

## Want to help?

Got a bug fix, or a new feature? Create a pull request and go for it!

## Let me know!

If you use **Reachability.swift**, please let me know about your app and I'll put a link [here…](https://github.com/ashleymills/Reachability.swift/wiki/Apps-using-Reachability.swift) and tell your friends!

Cheers,
Ash
