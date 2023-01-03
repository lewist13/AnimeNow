// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "AnimeNow",
    platforms: [
        .iOS(.v14),
        .macOS(.v11)
    ],
    products: [
        /// Features
        .library(name: "AnimeDetailFeature", targets: ["AnimeDetailFeature"]),
        .library(name: "AnimePlayerFeature", targets: ["AnimePlayerFeature"]),
        .library(name: "AppFeature", targets: ["AppFeature"]),
        .library(name: "CollectionsFeature", targets: ["CollectionsFeature"]),
        .library(name: "DownloadsFeature", targets: ["DownloadsFeature"]),
        .library(name: "DownloadOptionsFeature", targets: ["DownloadOptionsFeature"]),
        .library(name: "EditCollectionFeature", targets: ["EditCollectionFeature"]),
        .library(name: "HomeFeature", targets: ["HomeFeature"]),
        .library(name: "ModalOverlayFeature", targets: ["ModalOverlayFeature"]),
        .library(name: "NewCollectionFeature", targets: ["NewCollectionFeature"]),
        .library(name: "SearchFeature", targets: ["SearchFeature"]),
        .library(name: "SettingsFeature", targets: ["SettingsFeature"]),

        /// Clients
        .library(name: "APIClient", targets: ["APIClient"]),
        .library(name: "AnimeClient", targets: ["AnimeClient"]),
        .library(name: "ChromeCastClient", targets: ["ChromeCastClient"]),
        .library(name: "DatabaseClient", targets: ["DatabaseClient"]),
        .library(name: "DiscordClient", targets: ["DiscordClient"]),
        .library(name: "DownloaderClient", targets: ["DownloaderClient"]),
        .library(name: "VideoPlayerClient", targets: ["VideoPlayerClient"]),
        .library(name: "UserDefaultsClient", targets: ["UserDefaultsClient"]),

        /// Other
        .library(name: "AnyPublisherStream", targets: ["AnyPublisherStream"]),
        .library(name: "SharedModels", targets: ["SharedModels"]),
        .library(name: "Utilities", targets: ["Utilities"]),
        .library(name: "ViewComponents", targets: ["ViewComponents"]),
        .library(name: "Logger", targets: ["Logger"])
    ],
    dependencies: [
        .package(url: "https://github.com/pointfreeco/swift-composable-architecture", exact: "0.45.0"),
        .package(url: "https://github.com/pointfreeco/xctest-dynamic-overlay.git", exact: "0.5.0"),
        .package(url: "https://github.com/pointfreeco/swiftui-navigation", exact: "0.2.0"),
        .package(url: "https://github.com/onevcat/Kingfisher.git", exact: "7.3.2"),
        .package(url: "https://github.com/thisIsTheFoxe/SwiftWebVTT.git", exact: "0.1.0"),
        .package(url: "https://github.com/NicholasBellucci/SociableWeaver.git", exact: "0.1.12"),
        .package(url: "https://github.com/apple/swift-collections.git", exact: "1.0.3"),
        .package(path: "Sources/SwordRPC"),
        .package(path: "Sources/OpenCastSwift")
    ],
    targets: [
        /// Features
        .target(
            name: "AnimeDetailFeature",
            dependencies: [
                "AnimeClient",
                "DatabaseClient",
                "DownloaderClient",
                "Logger",
                "SharedModels",
                "UserDefaultsClient",
                "Utilities",
                "ViewComponents",
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
                .product(name: "Kingfisher", package: "Kingfisher")
            ]
        ),
        .target(
            name: "AnimePlayerFeature",
            dependencies: [
                "AnimeClient",
                "DatabaseClient",
                "DownloadOptionsFeature",
                "Logger",
                "UserDefaultsClient",
                "VideoPlayerClient",
                "ViewComponents",
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
                .product(name: "Kingfisher", package: "Kingfisher"),
                .product(name: "SwiftWebVTT", package: "SwiftWebVTT")
            ]
        ),
        .target(
            name: "AppFeature",
            dependencies: [
                "AnimePlayerFeature",
                "AnimeDetailFeature",
                "ChromeCastClient",
                "CollectionsFeature",
                "DatabaseClient",
                "DiscordClient",
                "DownloaderClient",
                "DownloadsFeature",
                "HomeFeature",
                "ModalOverlayFeature",
                "SearchFeature",
                "SettingsFeature",
                "SharedModels",
                "UserDefaultsClient",
                "Utilities",
                "VideoPlayerClient",
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture")
            ]
        ),
        .target(
            name: "CollectionsFeature",
            dependencies: [
                "DatabaseClient",
                "SharedModels",
                "Utilities",
                "ViewComponents",
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture")
            ]
        ),
        .target(
            name: "DownloadOptionsFeature",
            dependencies: [
                "AnimeClient",
                "DownloaderClient",
                "SettingsFeature",
                "SharedModels",
                "Utilities",
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture")
            ]
        ),
        .target(
            name: "DownloadsFeature",
            dependencies: [
                "DatabaseClient",
                "DownloaderClient",
                "SharedModels",
                "Utilities",
                "VideoPlayerClient",
                "ViewComponents",
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture")
            ]
        ),
        .target(
            name: "EditCollectionFeature",
            dependencies: [
                "SharedModels",
                "ViewComponents",
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture")
            ]
        ),
        .target(
            name: "HomeFeature",
            dependencies: [
                "AnimeClient",
                "DatabaseClient",
                "Logger",
                "Utilities",
                "ViewComponents",
                "VideoPlayerClient",
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
                .product(name: "Kingfisher", package: "Kingfisher"),
                .product(name: "SwiftUINavigation", package: "swiftui-navigation")
            ]
        ),
        .target(
            name: "ModalOverlayFeature",
            dependencies: [
                "DownloadOptionsFeature",
                "EditCollectionFeature",
                "NewCollectionFeature",
                "ViewComponents",
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture")
            ]
        ),
        .target(
            name: "NewCollectionFeature",
            dependencies: [
                "DatabaseClient",
                "SharedModels",
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture")
            ]
        ),
        .target(
            name: "SearchFeature",
            dependencies: [
                "AnimeClient",
                "Logger",
                "SharedModels",
                "UserDefaultsClient",
                "Utilities",
                "ViewComponents",
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture")
            ]
        ),
        .target(
            name: "SettingsFeature",
            dependencies: [
                "Utilities",
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture")
            ]
        ),

        /// Clients
        .target(
            name: "AnimeClient",
            dependencies: [
                "APIClient",
                "Utilities",
                "SharedModels",
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture")
            ]
        ),
        .target(
            name: "APIClient",
            dependencies: [
                "Logger",
                "SharedModels",
                "Utilities",
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
                .product(name: "SociableWeaver", package: "SociableWeaver")
            ]
        ),
        .target(
            name: "ChromeCastClient",
            dependencies: [
                .byName(name: "OpenCastSwift"),
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture")
            ]
        ),
        .target(
            name: "DiscordClient",
            dependencies: [
                "APIClient",
                .product(name: "SwordRPC", package: "SwordRPC"),
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture")
            ]
        ),
        .target(
            name: "DatabaseClient",
            dependencies: [
                "Utilities",
                "SharedModels",
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
                .product(name: "OrderedCollections", package: "swift-collections")
            ],
            resources: [
                .copy("Resources/AnimeNow.xcdatamodeld")
            ]
        ),
        .target(
            name: "DownloaderClient",
            dependencies: [
                "Logger",
                "Utilities",
                "SharedModels",
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture")
            ]
        ),
        .target(
            name: "UserDefaultsClient",
            dependencies: [
                "SharedModels",
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture")
            ]
        ),
        .target(
            name: "VideoPlayerClient",
            dependencies: [
                "AnyPublisherStream",
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
                .product(name: "Kingfisher", package: "Kingfisher")
            ]
        ),

        /// Other
        .target(
            name: "SharedModels",
            dependencies: [
                "Utilities",
                .product(name: "SociableWeaver", package: "SociableWeaver")
            ]
        ),
        .target(
            name: "Utilities",
            dependencies: [
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
                .product(name: "OrderedCollections", package: "swift-collections")
            ]
        ),
        .target(
            name: "ViewComponents",
            dependencies: [
                "DownloaderClient",
                "SharedModels",
                "Utilities",
                .product(name: "Kingfisher", package: "Kingfisher")
            ]
        ),
        .target(name: "AnyPublisherStream"),
        .target(name: "Logger"),

        // Test Targets

        .testTarget(
            name: "VideoPlayerClientTests",
            dependencies: [
                "VideoPlayerClient"
            ]
        )
    ]
)
