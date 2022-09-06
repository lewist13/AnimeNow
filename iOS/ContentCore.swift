//
//  ContentCore.swift
//  Anime Now!
//
//  Created Erik Bautista on 9/4/22.
//  Copyright © 2022. All rights reserved.
//

import ComposableArchitecture

enum ContentCore {
    struct State: Equatable {
        var home = HomeCore.State()
        var search = SearchCore.State()
    }

    enum Action: Equatable {
        case onAppear
        case home(HomeCore.Action)
        case search(SearchCore.Action)
    }

    struct Environment {
        let animeList: AnimeListClient
    }
}

extension ContentCore {
    static var reducer = Reducer<ContentCore.State, ContentCore.Action, ContentCore.Environment>.combine(
        HomeCore.reducer.pullback(
            state: \.home,
            action: /ContentCore.Action.home,
            environment: { global in
                HomeCore.Environment(
                    animeList: global.animeList
                )
            }
        ),
        SearchCore.reducer.pullback(
            state: \.search,
            action: /ContentCore.Action.search,
            environment: { global in
                SearchCore.Environment(
                    animeList: global.animeList
                )
            }
        ),
        .init { state, action, environment in
            return .none
        }
    )
}
