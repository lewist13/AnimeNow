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
    typealias LoadableCollection = Loadable<[CollectionStore]>

    struct State: Equatable {
        var collections = LoadableCollection.idle
    }

    enum Action: Equatable {
        case onAppear
        case updatedCollections([CollectionStore])
    }

    @Dependency(\.repositoryClient) var repositoryClient
}

extension CollectionsReducer {
    @ReducerBuilder<State, Action>
    var body: Reduce<State, Action> {
        Reduce(self.core)
    }

    func core(into state: inout State, action: Action) -> EffectTask<Action> {
        switch action {
        case .onAppear:
            guard !state.collections.hasInitialized else { break }
            state.collections = .loading

            return .run { send in
                let observing: AsyncStream<[CollectionStore]> = repositoryClient.observe(nil, [], true)

                for await collections in observing {
                    await send(.updatedCollections(collections))
                }
            }

        case .updatedCollections(let collections):
            state.collections = .success(collections)
        }
        return .none
    }
}
