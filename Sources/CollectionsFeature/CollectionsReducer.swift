//
//  CollectionsReducer.swift
//  Anime Now!
//
//  Created by ErrorErrorError on 10/15/22.
//  Copyright © 2022. All rights reserved.
//

import Foundation
import SharedModels
import DatabaseClient
import ComposableArchitecture

public struct CollectionsReducer: ReducerProtocol {
    public struct State: Equatable {
        var favorites = [AnimeStore]()
        var collections: [CollectionStore] = []

        fileprivate var hasInitialized = false

        public init(
            favorites: [AnimeStore] = [AnimeStore](),
            collections: [CollectionStore] = []
        ) {
            self.favorites = favorites
            self.collections = collections
        }
    }

    public enum Action: Equatable {
        case onAppear
        case onAddNewCollectionTapped
        case onAnimeTapped(AnimeStore)
        case removeAnimeFromFavorites(AnimeStore)
        case removeAnimeFromCollection(CollectionStore.ID, AnimeStore)
        case updatedFavorites([AnimeStore])
        case updatedCollections([CollectionStore])
        case deleteCollection(id: CollectionStore.ID)
    }

    @Dependency(\.databaseClient) var databaseClient

    public init() { }

    public var body: some ReducerProtocol<State, Action> {
        Reduce(self.core)
    }
}

extension CollectionsReducer.State {
    var sortedCollections: IdentifiedArrayOf<CollectionStore> {
        .init(uniqueElements: collections.sorted(by: \.title.value))
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
                    let observing: AsyncStream<[AnimeStore]> = databaseClient.observe(
                        AnimeStore.all.where(\AnimeStore.isFavorite == true)
                    )

                    for await items in observing {
                        await send(.updatedFavorites(items))
                    }
                },
                .run { send in
                    let observing: AsyncStream<[CollectionStore]> = databaseClient.observe(CollectionStore.all)

                    for await collections in observing {
                        await send(.updatedCollections(collections))
                    }
                }
            )

        case .deleteCollection(id: let collectionId):
            guard let collection = state.collections[id: collectionId] else { break }
            return .run {
                try await databaseClient.delete(collection)
            }

        case .updatedFavorites(let favorites):
            state.favorites = favorites

        case .updatedCollections(let collections):
            state.collections = collections

        case .removeAnimeFromFavorites(let animeStore):
            return .run { [animeStore] in
                try await databaseClient.update(animeStore.id, \AnimeStore.isFavorite, false)
            }

        case .removeAnimeFromCollection(let collectionId, let animeStore):
            guard var collection = state.collections[id: collectionId] else { break }
            collection.animes.removeAll(where: { $0.id == animeStore.id })

            return .run { [collection] in
                try await databaseClient.insert(collection)
            }

        case .onAddNewCollectionTapped:
            break

        case .onAnimeTapped:
            break
        }
        return .none
    }
}
