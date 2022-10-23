//
//  CollectionReducer.swift
//  Anime Now!
//
//  Created by ErrorErrorError on 10/15/22.
//  Copyright © 2022. All rights reserved.
//

import ComposableArchitecture

struct CollectionReducer: ReducerProtocol {
    struct State: Equatable {
        
    }

    enum Action: Equatable {
        case onAppear
    }
}

extension CollectionReducer {
    @ReducerBuilder<State, Action>
    var body: Reduce<State, Action> {
        Reduce(self.core)
    }

    func core(into state: inout State, action: Action) -> EffectTask<Action> {
        return .none
    }
}
