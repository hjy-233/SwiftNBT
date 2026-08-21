// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "SwiftNBT",
    platforms: [
        .macOS(.v14),
    ],
    products: [
        .library(
            name: "SwiftNBT",
            targets: ["SwiftNBT"],
        ),
    ],
    targets: [
        .target(name: "SwiftNBT"),
        .testTarget(
            name: "SwiftNBTTests",
            dependencies: ["SwiftNBT"],
        ),
    ],
)
