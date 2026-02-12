// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "DisplayBalls",
    platforms: [
        .macOS(.v26)
    ],
    targets: [
        .target(
            name: "CGVirtualDisplay",
            dependencies: [],
            path: "Sources/CGVirtualDisplay",
            publicHeadersPath: "include",
            cSettings: [
                .headerSearchPath("include")
            ],
            linkerSettings: [
                .linkedFramework("CoreGraphics"),
                .linkedFramework("Foundation")
            ]
        ),
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .executableTarget(
            name: "DisplayBalls",
            dependencies: ["CGVirtualDisplay"],

        ),
    ]
)
