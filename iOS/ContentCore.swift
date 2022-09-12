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
        var settings = SettingsCore.State()
    }

    enum Action: Equatable {
        case onAppear
        case home(HomeCore.Action)
        case search(SearchCore.Action)
        case settings(SettingsCore.Action)
    }

    struct Environment {
        let listClient: AnimeListClient
    }
}

extension ContentCore {
    static var reducer = Reducer<ContentCore.State, ContentCore.Action, ContentCore.Environment>.combine(
        HomeCore.reducer.pullback(
            state: \.home,
            action: /ContentCore.Action.home,
            environment: { global in
                HomeCore.Environment(
                    listClient: global.listClient
                )
            }
        ),
        SearchCore.reducer.pullback(
            state: \.search,
            action: /ContentCore.Action.search,
            environment: { global in
                SearchCore.Environment(
                    animeList: global.listClient
                )
            }
        ),
        SettingsCore.reducer.pullback(
            state: \.settings,
            action: /ContentCore.Action.settings,
            environment: { _ in .init() }
        ),
        .init { state, action, environment in
            return .none
        }
    )
}
