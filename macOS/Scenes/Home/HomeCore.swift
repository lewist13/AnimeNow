//
//  HomeCore.swift
//  Anime Now!
//
//  Created Erik Bautista on 9/4/22.
//  Copyright © 2022. All rights reserved.
//

import ComposableArchitecture

enum HomeCore {
    struct State: Equatable {
        
    }

    enum Action: Equatable {
        case onAppear
    }

    struct Environment {

    }
}

extension HomeCore {
    static var reducer: Reducer<HomeCore.State, HomeCore.Action, HomeCore.Environment> {
        .init { state, action, environment in
            return .none
        }
    }
}
