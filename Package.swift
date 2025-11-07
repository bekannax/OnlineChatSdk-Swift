// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "OnlineChatSdk",
    platforms: [
        .iOS(.v13)
    ],
    products: [
        .library(
            name: "OnlineChatSdk",
            targets: ["OnlineChatSdk"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/bekannax/OnlineChatSdk-Swift.git", from: "0.3.5"),
    ],
    targets: [
        .target(
            name: "OnlineChatSdk"
        ),
        .testTarget(
            name: "OnlineChatSdkTests",
            dependencies: ["OnlineChatSdk"]
        ),
    ]
)
