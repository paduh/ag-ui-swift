// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "AGUISwift",
    platforms: [
        .iOS(.v13),
        .macOS(.v10_15),
        .tvOS(.v13),
        .watchOS(.v6)
    ],
    products: [
        .library(
            name: "AGUICore",
            targets: ["AGUICore"]),
        .library(
            name: "AGUIClient",
            targets: ["AGUIClient"]),
        .library(
            name: "AGUITools",
            targets: ["AGUITools"]),
    ],
    dependencies: [
        // Add your dependencies here
    ],
    targets: [
        .target(
            name: "AGUICore",
            dependencies: []),
        .target(
            name: "AGUIClient",
            dependencies: ["AGUICore"]),
        .target(
            name: "AGUITools",
            dependencies: ["AGUICore"]),
        .testTarget(
            name: "AGUICoreTests",
            dependencies: ["AGUICore"]),
        .testTarget(
            name: "AGUIClientTests",
            dependencies: ["AGUIClient"]),
        .testTarget(
            name: "AGUIToolsTests",
            dependencies: ["AGUITools"]),
    ]
)

