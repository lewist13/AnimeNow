//
//  DiscordClient.swift
//  
//
//  Created by ErrorErrorError on 12/29/22.
//  
//

import Foundation
import ComposableArchitecture

public struct DiscordClient {
    public let status: () -> AsyncStream<Status>
    public let isActive: Bool
    public let isConnected: Bool
    public let setActive: (Bool) async throws -> Void
    public let setActivity: (Activity?) async -> Void
}

extension DiscordClient {
    public enum Status: String, Equatable {
        case connected = "Connected"
        case failed = "Failed"
        case offline = "Offline"
    }

    public var isSupported: Bool {
        #if os(macOS)
        true
        #else
        false
        #endif
    }
}

extension DiscordClient {
    public enum Activity {
        case watching(WatchingInfo)
        case searching
        case looking

        public struct WatchingInfo {
            let name: String
            let episode: String
            let image: String
            let progress: Double
            let duration: Double

            public init(
                name: String,
                episode: String,
                image: String,
                progress: Double = 0,
                duration: Double = 0
            ) {
                self.name = name
                self.episode = episode
                self.image = image
                self.progress = progress
                self.duration = duration
            }
        }
    }
}

extension DiscordClient: DependencyKey {
    #if os(iOS)
    public static var liveValue: DiscordClient = .noop
    #endif
}

extension DependencyValues {
    public var discordClient: DiscordClient {
        get { self[DiscordClient.self] }
        set { self[DiscordClient.self] = newValue }
    }
}
