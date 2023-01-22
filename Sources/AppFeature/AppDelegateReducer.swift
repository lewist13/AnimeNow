//
//  AppDelegateReducer.swift
//
//  Created by ErrorErrorError on 11/1/22.
//  
//

import Utilities
import FileClient
import SharedModels
import DiscordClient
import DatabaseClient
import SettingsFeature
import DownloaderClient
import UserDefaultsClient
import ComposableArchitecture

public struct AppDelegateReducer: ReducerProtocol {
    public typealias State = UserSettings

    public enum Action: Equatable {
        case appDidFinishLaunching
        case appDidEnterBackground
        case appWillTerminate
        case userSettingsLoaded(Loadable<UserSettings>)
    }

    public var body: some ReducerProtocol<State, Action> {
        Reduce(self.core)
    }

    @Dependency(\.fileClient) var fileClient
    @Dependency(\.discordClient) var discordClient
    @Dependency(\.databaseClient) var databaseClient
    @Dependency(\.downloaderClient) var downloaderClient
    @Dependency(\.userDefaultsClient) var userDefaultsClient
}

extension AppDelegateReducer {
    func core(state: inout State, action: Action) -> EffectTask<Action> {
        switch action {
        case .appDidFinishLaunching:
            return .run { send in
                await withThrowingTaskGroup(of: Void.self) { group in
                    group.addTask {
                        if !userDefaultsClient.get(.hasClearedAllVideos) {
                            // Remove all videos from database on first time opening app launch to sync with
                            // store.
                            await downloaderClient.reset()
                            await userDefaultsClient.set(.hasClearedAllVideos, value: true)
                        }
                    }

                    group.addTask {
                        for title in CollectionStore.Title.allCases {
                            if try await databaseClient.fetch(CollectionStore.all.where(\CollectionStore.title == title)).first == nil {
                                let collection = CollectionStore(title: title)
                                try await databaseClient.insert(collection)
                            }
                        }
                    }

                    group.addTask {
                        await send(
                            .userSettingsLoaded(
                                .init { try await fileClient.loadUserSettings() }
                            )
                        )
                    }
                }
            }

        case .userSettingsLoaded(let result):
            state = result.value ?? state
            return .run { [state] send in
                try await discordClient.setActive(state.discordEnabled)
            }

        default:
            break
        }

        return .none
    }
}
