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
    typealias LoadableAnime = LoadableState<IdentifiedArrayOf<Anime>>
    struct State: Equatable {
        var topTrendingAnime: LoadableAnime = .preparing
        var topAiringAnime: LoadableAnime = .preparing
        var topUpcomingAnime: LoadableAnime = .preparing
        var highestRatedAnime: LoadableAnime = .preparing
        var mostPopularAnime: LoadableAnime = .preparing

        var currentlyWatchingEpisodes: [Episode] = []

        var animeDetail: AnimeDetailCore.State? = nil
    }

    enum Action: Equatable, BindableAction {
        case onAppear
        case animeTapped(Anime)
        case fetchedAnime(keyPath: WritableKeyPath<State, LoadableAnime>, result: Result<[Anime], API.Error>)
        case animeDetail(AnimeDetailCore.Action)
        case binding(BindingAction<HomeCore.State>)
    }

    struct Environment {
        let animeClient: AnimeClient
    }
}

extension HomeCore {
    static let reducer = Reducer<HomeCore.State, HomeCore.Action, HomeCore.Environment>.combine(
        AnimeDetailCore.reducer.optional().pullback(
            state: \.animeDetail,
            action: /HomeCore.Action.animeDetail,
            environment: { env in .init(animeClient: env.animeClient) }
        ),
        .init { state, action, environment in
            switch (action) {
            case .onAppear:
                if state.topAiringAnime.hasInitialized {
                   break
                }
                state.topTrendingAnime = .loading
                state.topAiringAnime = .loading
                state.topUpcomingAnime = .loading
                state.highestRatedAnime = .loading
                state.mostPopularAnime = .loading
                return .merge(
                    environment.animeClient.getTopTrendingAnime()
                        .subscribe(on: DispatchQueue.global(qos: .userInteractive))
                        .receive(on: DispatchQueue.main)
                        .catchToEffect()
                        .map { HomeCore.Action.fetchedAnime(keyPath: \.topTrendingAnime, result: $0) },
                    environment.animeClient.getTopUpcomingAnime()
                        .subscribe(on: DispatchQueue.global(qos: .userInteractive))
                        .receive(on: DispatchQueue.main)
                        .catchToEffect()
                        .map { HomeCore.Action.fetchedAnime(keyPath: \.topUpcomingAnime, result: $0) },
                    environment.animeClient.getTopAiringAnime()
                        .subscribe(on: DispatchQueue.global(qos: .userInteractive))
                        .receive(on: DispatchQueue.main)
                        .catchToEffect()
                        .map { HomeCore.Action.fetchedAnime(keyPath: \.topAiringAnime, result: $0) },
                    environment.animeClient.getHighestRatedAnime()
                        .subscribe(on: DispatchQueue.global(qos: .userInteractive))
                        .receive(on: DispatchQueue.main)
                        .catchToEffect()
                        .map { HomeCore.Action.fetchedAnime(keyPath: \.highestRatedAnime, result: $0) },
                    environment.animeClient.getMostPopularAnime()
                        .subscribe(on: DispatchQueue.global(qos: .userInteractive))
                        .receive(on: DispatchQueue.main)
                        .catchToEffect()
                        .map { HomeCore.Action.fetchedAnime(keyPath: \.mostPopularAnime, result: $0) }
                    )
            case .animeTapped(let anime):
                state.animeDetail = .init(anime: anime)
            case .fetchedAnime(let keyPath, let result):
                switch result {
                case .success(let anime):
                    state[keyPath: keyPath] = .success(.init(uniqueElements: anime))
                case .failure(let error):
                    print(error)
                    state[keyPath: keyPath] = .failed
                }
            case .binding(_):
                break
            case .animeDetail(.onClose):
                state.animeDetail = nil
            case .animeDetail(_):
                break
            }
            return .none
        }
    )
        .binding()
}
