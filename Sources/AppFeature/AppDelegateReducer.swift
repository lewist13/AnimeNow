//
//  AppDelegateReducer.swift
//
//  Created by ErrorErrorError on 11/1/22.
//  
//

import SharedModels
import DiscordClient
import DatabaseClient
import DownloaderClient
import UserDefaultsClient
import ComposableArchitecture

public struct AppDelegateReducer: ReducerProtocol {
    public struct State: Equatable {}

    public enum Action: Equatable {
        case appDidFinishLaunching
        case appDidEnterBackground
        case appWillTerminate
    }

    public var body: some ReducerProtocol<State, Action> {
        Reduce(self.core)
    }

    @Dependency(\.discordClient) var discordClient
    @Dependency(\.downloaderClient) var downloaderClient
    @Dependency(\.userDefaultsClient) var userDefaultsClient
    @Dependency(\.databaseClient) var databaseClient
}

extension AppDelegateReducer {
    func core(state: inout State, action: Action) -> EffectTask<Action> {
        switch action {
        case .appDidFinishLaunching:
            var effects: [EffectTask<Action>] = []

            if !userDefaultsClient.get(.hasShownOnboarding) {
                // TODO: Do something that will trigger firstLaunched
            }

            if !userDefaultsClient.get(.hasClearedAllVideos) {
                // Remove all videos from database on first time opening app launch to sync with
                // store.
                effects.append(
                    .run { _ in
                        await downloaderClient.reset()
                        await userDefaultsClient.set(.hasClearedAllVideos, value: true)
                    }
                )
            }

            if userDefaultsClient.get(.canEnableDiscord) {
                effects.append(
                    .run {
                        try await discordClient.setActive(true)
                    }
                )
            }

            effects.append(
                .run { _ in
                    for title in CollectionStore.Title.allCases {
                        if try await databaseClient.fetch(CollectionStore.all.where(\CollectionStore.title == title)).first == nil {
                            let collection = CollectionStore(title: title)
                            try await databaseClient.insert(collection)
                        }
                    }
                }
            )

            return .merge(effects)

        default:
            break
        }

        return .none
    }
}
