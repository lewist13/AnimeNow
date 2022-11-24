//  DownloadOptionsReducer.swift
//  Anime Now! (iOS)
//
//  Created by ErrorErrorError on 11/24/22.
//

import ComposableArchitecture

struct DownloadOptionsReducer: ReducerProtocol {
    struct State: Equatable {
        
    }

    enum Action: Equatable {
        
    }

    var body: some ReducerProtocol<State, Action> {
        Reduce(self.core)
    }
}

extension DownloadOptionsReducer {
    func core(_ state: inout State, _ action: Action) -> EffectTask<Action> {
        return .none
    }
}
