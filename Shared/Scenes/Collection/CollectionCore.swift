//
//  LibraryCore.swift
//  Anime Now!
//
//  Created by ErrorErrorError on 10/15/22.
//  Copyright © 2022. All rights reserved.
//

import ComposableArchitecture

struct CollectionCore: ReducerProtocol {
    struct State: Equatable {
        
    }

    enum Action: Equatable {
        case onAppear
    }

    func reduce(into state: inout State, action: Action) -> EffectTask<Action> {
        return .none
    }
}
