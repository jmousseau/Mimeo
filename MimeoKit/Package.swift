// swift-tools-version:5.1

import PackageDescription

let package = Package(
    name: "MimeoKit",
    platforms: [
        .iOS(.v13),
    ],
    products: [
        .library(
            name: "MimeoKit",
            targets: ["MimeoKit"]
        )
    ],
    dependencies: [
        .package(path: "../Iris")
    ],
    targets: [
        .target(
            name: "MimeoKit",
            dependencies: ["Iris"]
        )
    ]
)
