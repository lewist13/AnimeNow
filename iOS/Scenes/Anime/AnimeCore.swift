//
//  AnimeCore.swift
//  Anime Now!
//
//  Created Erik Bautista on 9/6/22.
//  Copyright © 2022. All rights reserved.
//

import ComposableArchitecture

enum AnimeCore {
    typealias State = Anime

    enum Action: Equatable {
        case onAppear
    }

    struct Environment {

    }
}

extension AnimeCore {
    static var reducer: Reducer<AnimeCore.State, AnimeCore.Action, AnimeCore.Environment> {
        .init { state, action, environment in
            return .none
        }
    }
}
