//  AppDelegateReducer.swift
//  Anime Now! (iOS)
//
//  Created by ErrorErrorError on 11/1/22.
//  
//

import SwiftORM
import ComposableArchitecture

struct AppDelegateReducer: ReducerProtocol {
    struct State: Equatable {}

    enum Action: Equatable {
        case appDidFinishLaunching
        case appDidEnterBackground
        case appWillTerminate
    }

    var body: some ReducerProtocol<State, Action> {
        Reduce(self.core)
    }

    @Dependency(\.downloaderClient) var downloaderClient
    @Dependency(\.userDefaultsClient) var userDefaultsClient
    @Dependency(\.repositoryClient) var repositoryClient
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

            effects.append(
                .run { _ in
                    for title in CollectionStore.Title.allCases {
                        if try await repositoryClient.fetch(CollectionStore.all.where(\CollectionStore.title == title)).first == nil {
                            let collection = CollectionStore(title: title)
                            try await repositoryClient.insert(collection)
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
