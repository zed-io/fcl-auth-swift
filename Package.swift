// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "FCLAuthSwift",
    platforms: [
        .iOS(.v13),
    ],
    products: [
        .library(
            name: "FCLAuthSwift",
            targets: ["FCLAuthSwift"]
        ),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "FCLAuthSwift",
            dependencies: [],
            resources: [.process("MockData/nft-mock.json")]
        ),
        .testTarget(
            name: "FCLAuthSwiftTests",
            dependencies: ["FCLAuthSwift"]
        ),
    ]
)
