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
    typealias LoadableAnimes = Loadable<[Anime]>

    struct State: Equatable {
        var query = ""
        var loadable = LoadableAnimes.idle
        var searched = [String]()
    }

    enum Action: Equatable {
        case onAppear
        case searchQueryChanged(String)
        case searchResult(TaskResult<[Anime]>)
        case searchHistory([String])
        case clearSearchHistory
        case onAnimeTapped(Anime)
    }

    @Dependency(\.mainQueue) var mainQueue
    @Dependency(\.animeClient) var animeClient
    @Dependency(\.userDefaultsClient) var userDefaultsClient

    var body: some ReducerProtocol<State, Action> {
        Reduce(self.core)
    }
}

extension SearchReducer {
    struct SearchAnimesDebounceID: Hashable {}

    func core(state: inout State, action: Action) -> EffectTask<Action> {
        switch action {
        case .onAppear:
            return .run { send in
                let searchedItems: [String] = try userDefaultsClient.dataForKey(.searchedItems)?.toObject() ?? []
                await send(.searchHistory(searchedItems))
            }

        case .searchHistory(let items):
            state.searched = items

        case .searchQueryChanged(let query):
            state.query = query

            guard !query.isEmpty else {
                state.loadable = .idle
                return .cancel(id: SearchAnimesDebounceID.self)
            }
            state.loadable = .loading

            return .run { send in
                try await withTaskCancellation(id: SearchAnimesDebounceID.self, cancelInFlight: true) {
                    try await mainQueue.sleep(for: .seconds(0.5))
                    await send(.searchResult(.init { try await animeClient.searchAnimes(query) }))
                }
            }

        case .searchResult(.success(let anime)):
            state.loadable = .success(anime)

        case .searchResult(.failure(let error)):
            print(error)
            state.loadable = .failed

        case .clearSearchHistory:
            state.searched.removeAll()
            return .fireAndForget { [state] in
                await userDefaultsClient.setData(.searchedItems, try state.searched.toData())
            }

        case .onAnimeTapped:
            if state.searched.contains(state.query) {
                state.searched.removeAll(where: { $0 == state.query })
            }

            if state.searched.count > 9 {
                state.searched.removeLast()
            }
            state.searched.insert(state.query, at: 0)
            return .fireAndForget { [state] in
                await userDefaultsClient.setData(.searchedItems, try state.searched.toData())
            }
        }
        return .none
    }
}
