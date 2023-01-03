// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required 
// to build this package.

import PackageDescription

let package = Package(
    name: "OpenCastSwift",
    platforms: [
        .iOS(.v14),
        .macOS(.v11)
    ],
    products: [
        .library(name: "OpenCastSwift", targets: ["OpenCastSwift"])
    ],
    dependencies: [
        .package(
            url: "https://github.com/apple/swift-protobuf.git",
            from: "1.20.3"
        ),
        .package(
            url: "https://github.com/SwiftyJSON/SwiftyJSON.git",
            from: "5.0.0"
        )
    ],
    targets: [
        .target(
            name: "OpenCastSwift",
            dependencies: [
                .product(name: "SwiftProtobuf", package: "swift-protobuf"),
                .product(name: "SwiftyJSON", package: "SwiftyJSON")
            ]
        )
    ]
)
