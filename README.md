# Reachability.swift

Replacement for Apple's Reachability re-written in Swift with callbacks

Inspired by https://github.com/tonymillion/Reachability 

NOTE:

As of Swift 1.1, you cannot convert Swift closures into C-function pointers, meaning we can't set an `SCNetworkReachabilityCallBack`.

To get around this, this reachability replacement uses an `NSTimer` firing at 1/2 second intervals.

## Use

Just drop the **Reachability.swift** file into your project. That's it!

## Example

    let reachability = Reachability.reachabilityForInternetConnection()

    reachability.reachableBlock = { reachability in
        if reachability.isReachableViaWiFi() {
            println("\(Reachable via WiFi)")
        } else {
            println("\(Reachable via Cellular)")
        }
    }
    reachability.unreachableBlock = { reachability in
        println("\(Not reachable)")
    }

    reachability.startNotifier()

## Let me know

If you use **Reachability.swift**, please let me know… and tell your friends! 

Cheers,
Ash

