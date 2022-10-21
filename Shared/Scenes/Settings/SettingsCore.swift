//
//  SettingsCore.swift
//  Anime Now!
//
//  Created by ErrorErrorError on 9/8/22.
//  Copyright © 2022. All rights reserved.
//

import ComposableArchitecture

enum SettingsCore {
    struct State: Equatable {
        
    }

    enum Action: Equatable {
        case onAppear
    }

    struct Environment {

    }
}

extension SettingsCore {
    static var reducer: Reducer<SettingsCore.State, SettingsCore.Action, SettingsCore.Environment> {
        .init { state, action, environment in
            return .none
        }
    }
}
