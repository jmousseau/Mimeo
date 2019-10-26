// swift-tools-version:5.1

import PackageDescription

let package = Package(
    name: "FontClassifier",
    platforms: [
        .iOS(.v13),
    ],
    products: [
        .library(
            name: "FontClassifier",
            targets: ["FontClassifier"]
        )
    ],
    dependencies: [
        .package(path: "./Iris")
    ],
    targets: [
        .target(
            name: "FontClassifier",
            dependencies: ["Iris"]
        )
    ]
)
