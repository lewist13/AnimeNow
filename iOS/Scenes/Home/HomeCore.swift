//
//  HomeCore.swift
//  Anime Now!
//
//  Created Erik Bautista on 9/4/22.
//  Copyright © 2022. All rights reserved.
//

import Foundation
import ComposableArchitecture
import SwiftUI

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
        case setAnimeDetail(AnimeDetailCore.State?)
        case fetchedAnime(keyPath: WritableKeyPath<State, LoadableAnime>, result: Result<[Anime], API.Error>)
        case animeDetail(AnimeDetailCore.Action)
        case binding(BindingAction<HomeCore.State>)
    }

    struct Environment {
        let animeClient: AnimeClient
        let mainQueue: AnySchedulerOf<DispatchQueue>
        let mainRunLoop: AnySchedulerOf<RunLoop>
    }
}

extension HomeCore {
    static let reducer = Reducer<HomeCore.State, HomeCore.Action, HomeCore.Environment>.combine(
        AnimeDetailCore.reducer.optional().pullback(
            state: \.animeDetail,
            action: /HomeCore.Action.animeDetail,
            environment: {
                .init(
                    animeClient: $0.animeClient,
                    mainQueue: $0.mainQueue,
                    mainRunLoop: $0.mainRunLoop
                )
            }
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
                        .receive(on: environment.mainQueue)
                        .catchToEffect()
                        .map { HomeCore.Action.fetchedAnime(keyPath: \.topTrendingAnime, result: $0) },
                    environment.animeClient.getTopUpcomingAnime()
                        .subscribe(on: DispatchQueue.global(qos: .userInteractive))
                        .receive(on: environment.mainQueue)
                        .catchToEffect()
                        .map { HomeCore.Action.fetchedAnime(keyPath: \.topUpcomingAnime, result: $0) },
                    environment.animeClient.getTopAiringAnime()
                        .subscribe(on: DispatchQueue.global(qos: .userInteractive))
                        .receive(on: environment.mainQueue)
                        .catchToEffect()
                        .map { HomeCore.Action.fetchedAnime(keyPath: \.topAiringAnime, result: $0) },
                    environment.animeClient.getHighestRatedAnime()
                        .subscribe(on: DispatchQueue.global(qos: .userInteractive))
                        .receive(on: environment.mainQueue)
                        .catchToEffect()
                        .map { HomeCore.Action.fetchedAnime(keyPath: \.highestRatedAnime, result: $0) },
                    environment.animeClient.getMostPopularAnime()
                        .subscribe(on: DispatchQueue.global(qos: .userInteractive))
                        .receive(on: environment.mainQueue)
                        .catchToEffect()
                        .map { HomeCore.Action.fetchedAnime(keyPath: \.mostPopularAnime, result: $0) }
                    )
            case .fetchedAnime(let keyPath, .success(let anime)):
                state[keyPath: keyPath] = .success(.init(uniqueElements: anime))
            case .fetchedAnime(let keyPath, .failure(let error)):
                print(error)
                state[keyPath: keyPath] = .failed

            // Anime Detail

            case .setAnimeDetail(let animeMaybe):
                state.animeDetail = animeMaybe
            case .animeTapped(let anime):
                return .init(value: .setAnimeDetail(.init(anime: anime)))
                    .receive(
                        on: environment.mainQueue.animation(
                            .spring(
                                response: 0.4,
                                dampingFraction: 0.8
                            )
                        )
                    )
                    .eraseToEffect()
            case .animeDetail(.close):
                return .init(value: .setAnimeDetail(nil))
                    .receive(on: environment.mainQueue.animation(.linear(duration: 0.2)))
                    .eraseToEffect()
            case .animeDetail:
                break

            // Binding
            case .binding:
                break
            }
            return .none
        }
    )
        .binding()
}
