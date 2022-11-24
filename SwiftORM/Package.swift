// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SwiftORM",
    platforms: [
        .iOS(.v13),
        .macOS(.v10_15)
    ],
    products: [
        .library(
            name: "SwiftORM",
            targets: ["SwiftORM"]
        ),
    ],
    dependencies: [
        .package(
            url: "https://github.com/apple/swift-collections.git",
            from: "1.0.3"
        )
    ],
    targets: [
        .target(
            name: "SwiftORM",
            dependencies: [
                .product(
                    name: "Collections",
                    package: "swift-collections"
                )
            ]
        ),
        .testTarget(
            name: "SwiftORMTests",
            dependencies: [
                "SwiftORM",
                .product(
                    name: "Collections",
                    package: "swift-collections"
                )
            ]
        )
    ]
)
