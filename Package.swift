// swift-tools-version: 5.8
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "StreamKit",
    platforms: [
        .macOS(.v12),
        .iOS(.v13)
    ],
    products: [
        .library(
            name: "StreamKit",
            targets: ["StreamKit"]),
    ],
    dependencies: [
        .package(name: "Core", path: "./Core"),
    ],
    targets: [
        .target(
            name: "StreamKit",
            dependencies: [
                .product(name: "Core", package: "Core"),
            ],
            path: "Sources"),
        .testTarget(
            name: "StreamKitTests",
            dependencies: ["StreamKit"],
            path: "Tests",
            resources: [
                .copy("Resources/1MB"),
                .copy("Resources/16B"),
                .copy("Resources/PlainText"),
                .copy("Resources/PlainText.gz"),
            ]),
    ]
    
)
