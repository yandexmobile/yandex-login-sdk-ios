// swift-tools-version:5.7
import PackageDescription

let package = Package(
    name: "YandexLoginSDK",
    platforms: [.iOS(.v12)],
    products: [
        .library(
            name: "YandexLoginSDK",
            type: .static,
            targets: ["YandexLoginSDK"]
        ),
    ],
    targets: [
        .target(
            name: "YandexLoginSDK",
            path: "lib",
            sources: ["Classes"],
            publicHeadersPath: "Classes/Public",
            cSettings: [
                .unsafeFlags([
                    "-Werror",
                    "-Wall",
                    "-Wsign-compare",
                    "-Wdocumentation-unknown-command",
                    "-Wdocumentation",
                    "-Wnewline-eof",
                    "-Wobjc-interface-ivars",
                    "-Woverriding-method-mismatch",
                    "-Wsuper-class-method-mismatch",
                ]),
                .headerSearchPath("Classes/Private"),
                .headerSearchPath("Classes/Private/Core"),
                .headerSearchPath("Classes/Private/Core/Executor"),
                .headerSearchPath("Classes/Private/Core/Storage"),
                .headerSearchPath("Classes/Private/Networking"),
                .headerSearchPath("Classes/Private/Networking/RequestParams"),
                .headerSearchPath("Classes/Private/Networking/ResponseParser")
            ],
            linkerSettings: [.unsafeFlags(["-ObjC"])]
        )
    ]
)
