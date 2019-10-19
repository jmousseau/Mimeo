// swift-tools-version:5.1

import PackageDescription

let package = Package(
    name: "MimeoKit",
    products: [
        .library(
            name: "MimeoKit",
            targets: ["MimeoKit"]
        )
    ],
    targets: [
        .target(
            name: "MimeoKit",
            dependencies: []
        )
    ]
)
