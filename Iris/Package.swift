// swift-tools-version:5.1

import PackageDescription

let package = Package(
    name: "Iris",
    platforms: [
        .iOS(.v10),
        .macOS(.v10_15)
    ],
    products: [
        .library(
            name: "Iris",
            targets: ["Iris"]
        )
    ],
    targets: [
        .target(
            name: "Iris",
            dependencies: []
        )
    ]
)
