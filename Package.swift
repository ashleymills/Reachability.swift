// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Reachability",
    products: [
        .library(
            name: "Reachability",
            targets: ["Reachability"]),
    ],
    targets: [
        .target(
            name: "Reachability",
            dependencies: [],
            path: "Sources",
            resources: [.copy("PrivacyInfo.xcprivacy")]
        ),
        .testTarget(
            name: "ReachabilityTests",
            dependencies: ["Reachability"],
            path: "Tests"),
    ]
)
