// swift-tools-version:5.1

import PackageDescription

let package = Package(
    name: "FontClassifier",
    platforms: [
        .iOS(.v13),
        .macOS(.v10_15)
    ],
    products: [
        .library(
            name: "FontClassifier",
            targets: ["FontClassifier"]
        )
    ],
    dependencies: [
        .package(path: "../Iris"),
        .package(url: "https://github.com/JohnSundell/Files", from: "4.0.0"),
        .package(url: "https://github.com/jakeheis/SwiftCLI", from: "5.0.0")
    ],
    targets: [
        .target(
            name: "FontClassifier",
            dependencies: ["Iris"]
        ),
        .target(
            name: "FontClassifierCLI",
            dependencies: ["FontClassifier", "SwiftCLI", "Files"]
        )
    ]
)
