//
//  LibraryCore.swift
//  Anime Now!
//
//  Created Erik Bautista on 10/15/22.
//  Copyright © 2022. All rights reserved.
//

import ComposableArchitecture

enum CollectionCore {
    struct State: Equatable {
        
    }

    enum Action: Equatable {
        case onAppear
    }

    struct Environment {

    }
}

extension CollectionCore {
    static var reducer: Reducer<CollectionCore.State, CollectionCore.Action, CollectionCore.Environment> {
        .init { state, action, environment in
            return .none
        }
    }
}
