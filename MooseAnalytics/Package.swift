// swift-tools-version:5.1

import PackageDescription

let package = Package(
    name: "MooseAnalytics",
    platforms: [
        .iOS(.v10),
    ],
    products: [
        .library(
            name: "MooseAnalytics",
            targets: ["MooseAnalytics"]
        )
    ],
    targets: [
        .target(
            name: "MooseAnalytics",
            dependencies: []
        )
    ]
)
