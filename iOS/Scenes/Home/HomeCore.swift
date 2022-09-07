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
    }

    enum Action: Equatable {
        case onAppear
        case trendingAnimeFetched([Anime])
    }

    struct Environment {
        let animeList: ListClient
    }
}

extension HomeCore {
    static var reducer: Reducer<HomeCore.State, HomeCore.Action, HomeCore.Environment> {
        .init { state, action, environment in
            switch (action) {
            case .onAppear:
                return environment.animeList.trendingAnime()
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
                    }
            case .trendingAnimeFetched(let anime):
                state.trendingAnime = anime
            }
            return .none
        }
    }
}
