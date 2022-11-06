//
//  CollectionDetailReducer.swift
//  Anime Now!
//
//  Created by ErrorErrorError on 10/15/22.
//  Copyright © 2022. All rights reserved.
//

import Foundation
import ComposableArchitecture

struct CollectionDetailReducer: ReducerProtocol {
    struct State: Equatable {
    }

    enum Action: Equatable {
        case onAppear
    }

    @Dependency(\.repositoryClient) var repositoryClient

    var body: some ReducerProtocol<State, Action> {
        Reduce(self.core)
    }
}

extension CollectionDetailReducer {
    func core(into state: inout State, action: Action) -> EffectTask<Action> {
        switch action {
        case .onAppear:
            break
        }
        return .none
    }
}
