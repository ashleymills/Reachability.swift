
# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/en/1.0.0/)
and this project adheres to [Semantic Versioning](http://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [4.3.1] - 2018-10-18
### Fixed 
- Link CoreTelephony.framework required in iOS 12 (@corteggo)
### Changed 
- Updates for Swift 5.0 (@simonboriis)
- `strongSelf` -> `self` (@strawb3rryx7)

## [4.3.0] - 2018-10-01
### Changed 
- Updates for Swift 4.2

## [4.2.1] - 2018-08-30
### Fixed 
- Set reachabilty flags if `connection` called before `startNotifier` (https://github.com/ashleymills/Reachability.swift/issues/307)

## [4.2.0] - 2018-08-29
### Changed
- Use a single target for all platforms
- Add **ReachabilityTests** target
- Remove logging
- `Notification.Name.reachabilityChanged` is public
- Added optional `queueQoS`  and `targetQueue` to `init(reachabilityRef: SCNetworkReachability, queueQoS: DispatchQoS = .default, targetQueue: DispatchQueue? = nil)`
- Added optional `queueQoS`  and `targetQueue` to `init?(hostname: String, queueQoS: DispatchQoS = .default, targetQueue: DispatchQueue? = nil)`
- Added optional `queueQoS`  and `targetQueue` to `init?(queueQoS: DispatchQoS = .default, targetQueue: DispatchQueue? = nil)`
- Move macOS deployment target to 10.10


## [4.1.0] - 2017-10-10
### Changed

- Version update only to fix Cocoapods issue

## [4.0.0] - 2017-10-10
### Changed
- `NetworkStatus` renamed `Connection`
- `currentReachabilityStatus` renamed `connection`
- `isReachableViaWWAN` has been renamed to `isReachableViaCellular`
- `reachableOnWWAN` has been renamed to `allowsCellularConnection`
- The notification for reachability changes has been renamed from `ReachabilityChangedNotification` to `Notification.Name.reachabilityChanged`
- All closure callbacks and notification are fired on the main queue (including when `startNotifier()` is called)

### Deprecated
- `reachability.currentReachabilityString` has been deprecated. Use `"\(reachability.connection)"` instead.
- `isReachable` has been deprecated. Use `connection != .none` instead.
- `isReachableViaWWAN` has been deprecated. Use `connection == .cellular` instead.
