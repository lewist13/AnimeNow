//
//  SearchReducer.swift
//  Anime Now!
//
//  Created by ErrorErrorError on 9/4/22.
//  Copyright © 2022. All rights reserved.
//

import Foundation
import ComposableArchitecture

struct SearchReducer: ReducerProtocol {
    typealias LoadableAnimes = LoadableState<[Anime]>

    struct State: Equatable {
        var loadable = LoadableAnimes.idle
        var query = ""
    }

    enum Action: Equatable {
        case onAppear
        case searchQueryChanged(String)
        case searchResult(TaskResult<[Anime]>)
        case searchQueryChangeDebounce
        case onAnimeTapped(Anime)
    }

    @Dependency(\.mainQueue) var mainQueue
    @Dependency(\.animeClient) var animeClient
}

extension SearchReducer {
    @ReducerBuilder<State, Action>
    var body: Reduce<State, Action> {
        Reduce(self.core)
    }

    struct SearchAnimesDebounceID: Hashable {}

    func core(state: inout State, action: Action) -> EffectTask<Action> {
        switch action {
        case .onAppear:
            break
        case .searchQueryChanged(let query):
            state.query = query

            guard !query.isEmpty else {
                state.loadable = .idle
                return .cancel(id: SearchAnimesDebounceID.self)
            }
            state.loadable = .loading

            return .task { [query] in
                await .searchResult(.init { try await animeClient.searchAnimes(query) })
            }
            .debounce(id: SearchAnimesDebounceID.self, for: 0.3, scheduler: mainQueue)

        case .searchResult(.success(let anime)):
            state.loadable = .success(anime)

        case .searchResult(.failure):
            state.loadable = .failed

        case .searchQueryChangeDebounce:
            break

        case .onAnimeTapped:
            break
        }
        return .none
    }
}
