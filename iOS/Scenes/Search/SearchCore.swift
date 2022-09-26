//
//  SearchCore.swift
//  Anime Now!
//
//  Created Erik Bautista on 9/4/22.
//  Copyright © 2022. All rights reserved.
//

import Foundation
import ComposableArchitecture

enum SearchCore {
    typealias LoadableAnimes = LoadableState<IdentifiedArrayOf<Anime>>

    struct State: Equatable {
        var loadable = LoadableAnimes.preparing
        var query = ""
    }

    enum Action: Equatable {
        case onAppear
        case searchQueryChanged(String)
        case searchResult(Result<[Anime], API.Error>)
        case searchQueryChangeDebounce
        case onAnimeTapped(Anime)
    }

    struct Environment {
        let mainQueue: AnySchedulerOf<DispatchQueue>
        let animeClient: AnimeClient
    }
}

extension SearchCore {
    static var reducer: Reducer<SearchCore.State, SearchCore.Action, SearchCore.Environment> {
        .init { state, action, environment in
            enum SearchAnimesID {}

            switch action {
            case .onAppear:
                break
            case .searchQueryChanged(let query):
                state.query = query

                guard !query.isEmpty else {
                    state.loadable = .preparing
                    return .cancel(id: SearchAnimesID.self)
                }
                state.loadable = .loading
                return environment.animeClient
                    .searchAnimes(query)
                    .debounce(id: SearchAnimesID.self, for: 0.3, scheduler: environment.mainQueue)
                    .catchToEffect(Action.searchResult)
            case .searchResult(.success(let anime)):
                state.loadable = .success(.init(uniqueElements: anime))
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
}
