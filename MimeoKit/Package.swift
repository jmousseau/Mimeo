// swift-tools-version:5.3

import PackageDescription

let package = Package(
    name: "MimeoKit",
    platforms: [
        .iOS(.v14),
    ],
    products: [
        .library(
            name: "MimeoKit",
            targets: ["MimeoKit"]
        )
    ],
    dependencies: [
        .package(path: "../FontClassifier"),
        .package(path: "../Iris")
    ],
    targets: [
        .target(
            name: "MimeoKit",
            dependencies: ["FontClassifier", "Iris"]
        )
    ]
)
