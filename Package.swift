// swift-tools-version: 5.8
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "StreamKit",
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "StreamKit",
            targets: ["StreamKit"]),
    ],
    dependencies: [
        .package(path: "./Core")
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "StreamKit",
            dependencies: [
                .product(name: "Core", package: "Core")
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
