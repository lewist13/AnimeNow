// swift-tools-version:5.5

import PackageDescription

let package = Package(
    name: "SwordRPC",
    platforms: [
        .macOS(.v10_15),
        .iOS(.v13)
    ],
    products: [
        .library(
            name: "SwordRPC",
            targets: ["SwordRPC"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/swhitty/FlyingFox.git", .upToNextMajor(from: "0.10.0"))
    ],
    targets: [
        .target(
            name: "SwordRPC",
            dependencies: [
                .product(name: "FlyingFox", package: "FlyingFox")
            ]
        ),
    ]
)
