// swift-tools-version:5.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "YandexLoginSDK",
    platforms: [
        .iOS(.v12),
    ],
    products: [
        .library(
            name: "YandexLoginSDK",
            targets: ["YandexLoginSDK"]),
    ],
    dependencies: [
    ],
    targets: [
        .target(
            name: "YandexLoginSDK",
            path: "package",
            publicHeadersPath: "."),
    ]
)
