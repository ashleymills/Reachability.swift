
# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/en/1.0.0/)
and this project adheres to [Semantic Versioning](http://semver.org/spec/v2.0.0.html).

## [Unreleased]

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
