//
//  HomeCore.swift
//  Anime Now!
//
//  Created Erik Bautista on 9/4/22.
//  Copyright © 2022. All rights reserved.
//

import Foundation
import ComposableArchitecture

enum HomeCore {
    struct State: Equatable {
        var trendingAnime: [Anime] = []
        var currentlyWatchingEpisodes: [Episode] = []
        var recentlyReleasedAnime: [Anime] = []
    }

    enum Action: Equatable {
        case onAppear
        case tappedAnime
        case trendingAnimeFetched([Anime])
        case recentlyReleasedAnimeFetched([Anime])
    }

    struct Environment {
        let listClient: ListClient
    }
}

extension HomeCore {
    static let reducer = Reducer<HomeCore.State, HomeCore.Action, HomeCore.Environment>.combine(
//        AnimeCore.reducer.forEach(
//            state: <#T##WritableKeyPath<GlobalState, [AnimeCore.State]>#>,
//            action: <#T##CasePath<GlobalAction, (Int, AnimeCore.Action)>#>,
//            environment: <#T##(GlobalEnvironment) -> AnimeCore.Environment#>
//        )
//        ,
        .init { state, action, environment in
            switch (action) {
            case .onAppear:
                return .concatenate(
                    environment.listClient.trendingAnime()
                        .subscribe(on: DispatchQueue.global(qos: .userInteractive))
                        .receive(on: DispatchQueue.main)
                        .catchToEffect()
                        .map { result in
                            switch result {
                            case .success(let anime):
                                return HomeCore.Action.trendingAnimeFetched(anime)
                            case .failure(let error):
                                print(error)
                                return HomeCore.Action.trendingAnimeFetched([])
                            }
                        },
                    environment.listClient.recentlyReleasedAnime()
                        .subscribe(on: DispatchQueue.global(qos: .userInteractive))
                        .receive(on: DispatchQueue.main)
                        .catchToEffect()
                        .map { result in
                            switch result {
                            case .success(let anime):
                                return HomeCore.Action.recentlyReleasedAnimeFetched(anime)
                            case .failure(let error):
                                print(error)
                                return HomeCore.Action.recentlyReleasedAnimeFetched([])
                            }
                        }
                    )
            case .tappedAnime:
                break
            case .trendingAnimeFetched(let anime):
                state.trendingAnime = anime
            case .recentlyReleasedAnimeFetched(let anime):
                state.recentlyReleasedAnime = anime
            }
            return .none
        }
    )
}
