//
//  SettingsReducer.swift
//  Anime Now!
//
//  Created by ErrorErrorError on 9/8/22.
//  Copyright © 2022. All rights reserved.
//

import ComposableArchitecture

public struct SettingsReducer: ReducerProtocol {
    public init() {}

    public struct State: Equatable {
        public init() {
        }
    }

    public enum Action: Equatable {
        case initialize
        case onAppear
    }

    public var body: some ReducerProtocol<State, Action> {
        Reduce(self.core)
    }
}

extension SettingsReducer {
    func core(state: inout State, action: Action) -> EffectTask<Action> {
        return .none
    }
}
