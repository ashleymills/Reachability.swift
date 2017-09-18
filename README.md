# Reachability.swift

Reachability.swift is a replacement for Apple's Reachability sample, re-written in Swift with closures.

It is compatible with **iOS** (8.0 - 11.0), **OSX** (10.9 - 10.13) and **tvOS** (9.0 - 11.0)

Inspired by https://github.com/tonymillion/Reachability

# IMPORTANT

## Version 4.0 breaking changes#

### Previously


```swift
enum NetworkStatus {
    case notReachable, reachableViaWiFi, reachableViaWWAN
}
var currentReachabilityStatus: NetworkStatus
```

### Now:

```swift
enum Connection {
    case none, wifi, cellular
}
var connection: Connection
```

### Other changes:

- `isReachableViaWWAN` has been renamed to `isReachableViaCellular`

- `reachableOnWWAN` has been renamed to `allowsCellularConnection`

- `reachability.currentReachabilityString` has been deprecated. Use `"\(reachability.connection)"` instead.

- `isReachable` has been deprecated. Use `connection != .none` instead.

- `isReachableViaWWAN` has been deprecated. Use `connection == .cellular` instead.

- The notification for reachability changes has been renamed from `ReachabilityChangedNotification` to `Notification.Name.reachabilityChanged`

- All closure callbacks and notification are fired on the main queue (including when `startNotifier()` is called)


## Got a problem?

Please read https://github.com/ashleymills/Reachability.swift/wiki/Raising-an-issue before raising an issue.

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

NOTE: All closures are run on the **main queue**.

```swift
//declare this property where it won't go out of scope relative to your listener
let reachability = Reachability()!

reachability.whenReachable = { reachability in
    if reachability.isReachableViaWiFi {
        print("Reachable via WiFi")
    } else {
        print("Reachable via Cellular")
    }
}
reachability.whenUnreachable = { reachability in
    print("Not reachable")
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

NOTE: All notifications are delviered on the **main queue**.

```swift
//declare this property where it won't go out of scope relative to your listener
let reachability = Reachability()!

//declare this inside of viewWillAppear

     NotificationCenter.default.addObserver(self, selector: #selector(self.reachabilityChanged),name: ReachabilityChangedNotification,object: reachability)
    do{
      try reachability.startNotifier()
    }catch{
      print("could not start reachability notifier")
    }
```

and

```swift
func reachabilityChanged(note: Notification) {

  let reachability = note.object as! Reachability

  if reachability.isReachable {
    if reachability.isReachableViaWiFi {
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
NotificationCenter.default.removeObserver(self,
                                          name: ReachabilityChangedNotification,
                                          object: reachability)
```

## Want to help?

Got a bug fix, or a new feature? Create a pull request and go for it!

## Let me know!

If you use **Reachability.swift**, please let me know about your app and I'll put a link [here…](https://github.com/ashleymills/Reachability.swift/wiki/Apps-using-Reachability.swift) and tell your friends!

Cheers,
Ash
