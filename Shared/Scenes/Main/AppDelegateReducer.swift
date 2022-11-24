//  AppDelegateReducer.swift
//  Anime Now! (iOS)
//
//  Created by ErrorErrorError on 11/1/22.
//  
//

import SwiftORM
import ComposableArchitecture

struct AppDelegateReducer: ReducerProtocol {
    struct State: Equatable {}

    enum Action: Equatable {
        case appDidFinishLaunching
        case appDidEnterBackground
        case appWillTerminate
    }

    var body: some ReducerProtocol<State, Action> {
        Reduce(self.core)
    }

    @Dependency(\.userDefaultsClient) var userDefaultsClient
    @Dependency(\.repositoryClient) var repositoryClient
}

extension AppDelegateReducer {
    func core(state: inout State, action: Action) -> EffectTask<Action> {
        switch action {
        case .appDidFinishLaunching:
            if !userDefaultsClient.boolForKey(.firstLaunched) {
                // TODO: Do something that will trigger firstLaunched
            }

            return .run { _ in
                for title in CollectionStore.Title.allCases {
                    if try await repositoryClient.fetch(CollectionStore.all.where(\CollectionStore.title == title)).first == nil {
                        let collection = CollectionStore(title: title)
                        try await repositoryClient.insert(collection)
                    }
                }
            }

        default:
            break
        }

        return .none
    }
}
