//
//  CollectionsReducer.swift
//  Anime Now!
//
//  Created by ErrorErrorError on 10/15/22.
//  Copyright © 2022. All rights reserved.
//

import Sworm
import Foundation
import ComposableArchitecture

struct CollectionsReducer: ReducerProtocol {
    struct State: Equatable {
        var favorites = [AnimeStore]()
        var collections: IdentifiedArrayOf<CollectionDetailReducer.State> = []
        var selection: Selection? = nil

        fileprivate var hasInitialized = false

        enum Selection: Equatable {
            case favorites
            case collection(selected: CollectionDetailReducer.State.ID)
        }
    }

    enum Action: Equatable {
        case onAppear
        case setSelection(selection: State.Selection?)
        case updatedFavorites([AnimeStore])
        case updatedCollections([CollectionStore])
        case collectionDetail(id: CollectionDetailReducer.State.ID, action: CollectionDetailReducer.Action)
    }

    @Dependency(\.repositoryClient) var repositoryClient

    var body: some ReducerProtocol<State, Action> {
        Reduce(self.core)
            .forEach(\.collections, action: /Action.collectionDetail(id:action:)) {
                CollectionDetailReducer()
            }
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
                        AnimeStore.all.where(\AnimeStore.isFavorite == true)
                    )

                    for await items in observing {
                        await send(.updatedFavorites(items))
                    }
                },
                .run { send in
                    let observing: AsyncStream<[CollectionStore]> = repositoryClient.observe(CollectionStore.all)

                    for await collections in observing {
                        await send(.updatedCollections(collections))
                    }
                }
            )

        case .setSelection(selection: let selection):
            state.selection = selection

        case .updatedFavorites(let favorites):
            state.favorites = favorites

        case .updatedCollections(let collections):
            state.collections = .init(uniqueElements: collections)

        case .collectionDetail(_, action: .close):
            state.selection = nil

        case .collectionDetail:
            break
        }
        return .none
    }
}
