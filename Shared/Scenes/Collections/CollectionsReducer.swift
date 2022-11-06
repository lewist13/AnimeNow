//
//  CollectionsReducer.swift
//  Anime Now!
//
//  Created by ErrorErrorError on 10/15/22.
//  Copyright © 2022. All rights reserved.
//

import Foundation
import ComposableArchitecture

struct CollectionsReducer: ReducerProtocol {
    struct State: Equatable {
        var favorites = [AnimeStore]()
        var collections = [CollectionStore]()
        var hasInitialized = false
    }

    enum Action: Equatable {
        case onAppear
        case updatedFavorites([AnimeStore])
        case updatedCollections([CollectionStore])
    }

    @Dependency(\.repositoryClient) var repositoryClient

    var body: some ReducerProtocol<State, Action> {
        Reduce(self.core)
    }
}

extension CollectionsReducer {
    func core(into state: inout State, action: Action) -> EffectTask<Action> {
        switch action {
        case .onAppear:
            guard !state.hasInitialized else { break }
            state.hasInitialized = true

            return .merge(
                .run { send in
                    let observing: AsyncStream<[AnimeStore]> = repositoryClient.observe(
                        .init(
                            format: "isFavorite = %d", 1
                        )
                    )

                    for await items in observing {
                        await send(.updatedFavorites(items))
                    }
                },
                .run { send in
                    let observing: AsyncStream<[CollectionStore]> = repositoryClient.observe()

                    for await collections in observing {
                        await send(.updatedCollections(collections))
                    }
                }
            )

        case .updatedFavorites(let favorites):
            state.favorites = favorites

        case .updatedCollections(let collections):
            state.collections = collections
        }
        return .none
    }
}
