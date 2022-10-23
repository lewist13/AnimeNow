//
//  SettingsReducer.swift
//  Anime Now!
//
//  Created by ErrorErrorError on 9/8/22.
//  Copyright © 2022. All rights reserved.
//

import ComposableArchitecture

struct SettingsReducer: ReducerProtocol {
    struct State: Equatable {
    }

    enum Action: Equatable {
        case onAppear
    }
}

extension SettingsReducer {
    @ReducerBuilder<State, Action>
    var body: Reduce<State, Action> {
        Reduce(self.core)
    }

    func core(state: inout State, action: Action) -> EffectTask<Action> {
        return .none
    }
}
