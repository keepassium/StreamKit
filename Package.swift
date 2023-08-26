// swift-tools-version: 5.8
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "StreamKit",
    products: [
        .library(
            name: "StreamKit",
            targets: ["StreamKit"]),
    ],
    targets: [
        .target(
            name: "StreamKit",
            dependencies: ["Core"],
            path: "Sources"),
        .target(
            name: "Core",
            path: "Core"),
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
