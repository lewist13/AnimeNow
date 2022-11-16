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
    typealias State = CollectionStore

    enum Action: Equatable {
        case onAppear
        case close
        case onAnimeTapped(AnimeStore)
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
        case .onAnimeTapped:
            break
        case .close:
            break
        }
        return .none
    }
}
