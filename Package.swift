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
            name: "CertificateTransparency",
            path: "Vendor/CertificateTransparency",
            exclude: ["README.md", "UPSTREAM.md", "LICENSE", "Package.swift", "CertificateTransparency.podspec"],
            sources: [
                "CertificateTransparency.mm", "auto_update_log_verifier.mm",
                "builtin_logs.cc", "builtin_root_certs.mm", "crypto_bytebuilder.cc",
                "crypto_bytestring.cc", "ct_log_downloader.mm", "ct_objects_extractor.cc",
                "ct_serialization.cc", "ec_public_key.mm", "log_verifier.cc",
                "multi_log_verifier.cc", "public_key.mm", "rsa_public_key.mm",
            ],
            publicHeadersPath: "include",
            cSettings: [
                .headerSearchPath("."),
                .define("NDEBUG", .when(configuration: .release)),
            ],
            linkerSettings: [.linkedFramework("Foundation"), .linkedFramework("Security")]
        ),
        .target(
            name: "YandexLoginSDK",
            dependencies: ["CertificateTransparency"]),
        .testTarget(
            name: "YandexLoginSDKTests",
            dependencies: ["YandexLoginSDK"]),
    ],
    swiftLanguageVersions: [.v5],
    cxxLanguageStandard: .cxx20
)
