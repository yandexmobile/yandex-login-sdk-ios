// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "CertificateTransparency",
    platforms: [
        .iOS("11.0"),
    ],
    products: [
        .library(
            name: "CertificateTransparency",
            targets: ["CertificateTransparency"]
        ),
    ],
    targets: [
        .target(
            name: "CertificateTransparency",
            path: ".",
            exclude: [
                "CertificateTransparency.podspec",
                "README.md",
                "tests",
            ],
            sources: [
                "CertificateTransparency.mm",
                "auto_update_log_verifier.mm",
                "builtin_logs.cc",
                "builtin_root_certs.mm",
                "crypto_bytebuilder.cc",
                "crypto_bytestring.cc",
                "ct_log_downloader.mm",
                "ct_objects_extractor.cc",
                "ct_serialization.cc",
                "ec_public_key.mm",
                "log_verifier.cc",
                "multi_log_verifier.cc",
                "public_key.mm",
                "rsa_public_key.mm",
            ],
            publicHeadersPath: "include",
            cSettings: [
                .headerSearchPath("."),
                .define("NDEBUG", .when(configuration: .release)),
            ],
            linkerSettings: [
                .linkedFramework("Foundation"),
                .linkedFramework("Security"),
            ]
        ),
        .target(
            name: "CertificateTransparencyTestSupport",
            path: "tests",
            exclude: [
                "CertificateTransparencyTests.swift",
            ],
            sources: [
                "test_certs.mm",
            ],
            publicHeadersPath: "include",
            cSettings: [
                .headerSearchPath("."),
            ],
            linkerSettings: [
                .linkedFramework("Foundation"),
                .linkedFramework("Security"),
            ]
        ),
        .testTarget(
            name: "CertificateTransparencyTests",
            dependencies: [
                "CertificateTransparency",
                "CertificateTransparencyTestSupport",
            ],
            path: "tests",
            exclude: [
                "include",
                "test_certs.h",
                "test_certs.mm",
            ],
            sources: [
                "CertificateTransparencyTests.swift",
            ]
        ),
    ],
    cxxLanguageStandard: .cxx20
)
