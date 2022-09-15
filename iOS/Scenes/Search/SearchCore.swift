//
//  SearchCore.swift
//  Anime Now!
//
//  Created Erik Bautista on 9/4/22.
//  Copyright © 2022. All rights reserved.
//

import ComposableArchitecture

enum SearchCore {
    struct State: Equatable {
        
    }

    enum Action: Equatable {
        case onAppear
    }

    struct Environment {
        var animeClient: AnimeClient
    }
}

extension SearchCore {
    static var reducer: Reducer<SearchCore.State, SearchCore.Action, SearchCore.Environment> {
        .init { state, action, environment in
            return .none
        }
    }
}
