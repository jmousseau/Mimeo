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
    dependencies: [
        .package(url: "https://github.com/SDWebImage/SDWebImage.git", from: "5.1.0")
    ],
    targets: [
        .target(
            name: "Iris",
            dependencies: ["SDWebImage"]
        )
    ]
)
