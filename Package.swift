// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "YandexLoginSDK",
    platforms: [.iOS(.v12)],
    products: [
        .library(
            name: "YandexLoginSDK",
            targets: ["YandexLoginSDK"]),
    ],
    targets: [
        .target(
            name: "YandexLoginSDK",
            dependencies: []),
        .testTarget(
            name: "YandexLoginSDKTests",
            dependencies: ["YandexLoginSDK"]),
    ],
    swiftLanguageVersions: [.v5]
)
