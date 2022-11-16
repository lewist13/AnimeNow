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
            guard !userDefaultsClient.boolForKey(.firstLaunched) else {
                break
            }

            return .run { _ in
                let inWatchlist = CollectionStore(
                    title: .planning
                )

                _ = try await repositoryClient.insert(inWatchlist)
                await userDefaultsClient.setBool(.firstLaunched, true)
            }
        default:
            break
        }

        return .none
    }
}
