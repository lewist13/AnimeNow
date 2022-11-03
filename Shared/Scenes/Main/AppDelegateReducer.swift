//  AppDelegateReducer.swift
//  Anime Now! (iOS)
//
//  Created by ErrorErrorError on 11/1/22.
//  
//

import ComposableArchitecture

struct AppDelegateReducer: ReducerProtocol {
    struct State: Equatable {}

    enum Action: Equatable {
        case appDidEnterBackground
        case appWillTerminate
    }

    @ReducerBuilder<State, Action>
    var body: Reduce<State, Action> {
        Reduce(self.core)
    }
}

extension AppDelegateReducer {
    func core(state: inout State, action: Action) -> EffectTask<Action> {
        .none
    }
}
