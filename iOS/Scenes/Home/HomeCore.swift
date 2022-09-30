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
    typealias LoadableEpisodes = LoadableState<IdentifiedArrayOf<EpisodeProgress>>

    struct State: Equatable {
        var topTrendingAnime: LoadableAnime = .idle
        var topAiringAnime: LoadableAnime = .idle
        var topUpcomingAnime: LoadableAnime = .idle
        var highestRatedAnime: LoadableAnime = .idle
        var mostPopularAnime: LoadableAnime = .idle
        var resumeWatching: LoadableEpisodes = .idle
    }

    enum Action: Equatable, BindableAction {
        case onAppear
        case animeTapped(Anime)
        case fetchedAnime(keyPath: WritableKeyPath<State, LoadableAnime>, result: Result<[Anime], API.Error>)
        case fetchedEpisodesProgress([EpisodeProgress])
        case binding(BindingAction<HomeCore.State>)
    }

    struct Environment {
        let animeClient: AnimeClient
        let mainQueue: AnySchedulerOf<DispatchQueue>
        let mainRunLoop: AnySchedulerOf<RunLoop>
        let repositoryClient: RepositoryClient
    }
}

extension HomeCore.State {
    var isLoading: Bool {
        !topTrendingAnime.hasInitialized || topTrendingAnime.isLoading ||
        !topAiringAnime.hasInitialized || topAiringAnime.isLoading ||
        !topUpcomingAnime.hasInitialized || topUpcomingAnime.isLoading ||
        !highestRatedAnime.hasInitialized || highestRatedAnime.isLoading ||
        !mostPopularAnime.hasInitialized || mostPopularAnime.isLoading ||
        !resumeWatching.hasInitialized || resumeWatching.isLoading
    }

    var hasInitialized: Bool {
        topTrendingAnime.hasInitialized &&
        topAiringAnime.hasInitialized &&
        topUpcomingAnime.hasInitialized &&
        highestRatedAnime.hasInitialized &&
        mostPopularAnime.hasInitialized
    }
}

extension HomeCore {
    static let reducer = Reducer<HomeCore.State, HomeCore.Action, HomeCore.Environment>.combine(
        .init { state, action, environment in
            switch (action) {
            case .onAppear:
                guard !state.hasInitialized else {
                    break
                }
                state.topTrendingAnime = .loading
                state.topAiringAnime = .loading
                state.topUpcomingAnime = .loading
                state.highestRatedAnime = .loading
                state.mostPopularAnime = .loading
                state.resumeWatching = .loading
                return .merge(
                    environment.animeClient.getTopTrendingAnime()
                        .receive(on: environment.mainQueue)
                        .catchToEffect()
                        .map { HomeCore.Action.fetchedAnime(keyPath: \.topTrendingAnime, result: $0) },
                    environment.animeClient.getTopUpcomingAnime()
                        .receive(on: environment.mainQueue)
                        .catchToEffect()
                        .map { HomeCore.Action.fetchedAnime(keyPath: \.topUpcomingAnime, result: $0) },
                    environment.animeClient.getTopAiringAnime()
                        .receive(on: environment.mainQueue)
                        .catchToEffect()
                        .map { HomeCore.Action.fetchedAnime(keyPath: \.topAiringAnime, result: $0) },
                    environment.animeClient.getHighestRatedAnime()
                        .receive(on: environment.mainQueue)
                        .catchToEffect()
                        .map { HomeCore.Action.fetchedAnime(keyPath: \.highestRatedAnime, result: $0) },
                    environment.animeClient.getMostPopularAnime()
                        .receive(on: environment.mainQueue)
                        .catchToEffect()
                        .map { HomeCore.Action.fetchedAnime(keyPath: \.mostPopularAnime, result: $0) },
                    environment.repositoryClient.observe(nil, [])
                        .receive(on: environment.mainQueue)
                        .eraseToEffect()
                        .map(Action.fetchedEpisodesProgress)
                )
            case .fetchedAnime(let keyPath, .success(let anime)):
                state[keyPath: keyPath] = .success(.init(uniqueElements: anime))
            case .fetchedAnime(let keyPath, .failure(let error)):
                print(error)
                state[keyPath: keyPath] = .failed
            case .fetchedEpisodesProgress(let episodesProgress):
                var filteredEpisodesProgress: [EpisodeProgress] = []

                for progressInfo in episodesProgress {
                    // We only want one episode for each anime that has been recent to be shown
                    let containsProgressInfoWithAnime = filteredEpisodesProgress.firstIndex(
                        where: {
                            $0.id.animeId == progressInfo.id.animeId
                        }
                    )
                    if let progressInfoAnimeIndex = containsProgressInfoWithAnime {
                        let element = filteredEpisodesProgress[progressInfoAnimeIndex]
                        if progressInfo.lastUpdated.compare(element.lastUpdated) == .orderedDescending {
                            filteredEpisodesProgress[progressInfoAnimeIndex] = progressInfo
                        }
                    } else {
                        filteredEpisodesProgress.append(progressInfo)
                    }
                }

                filteredEpisodesProgress = filteredEpisodesProgress.filter({ 0.9 > $0.progress && $0.progress > 0 })

                state.resumeWatching = .success(.init(uniqueElements: filteredEpisodesProgress))
            case .binding:
                break
            case .animeTapped:
                break
            }
            return .none
        }
    )
        .binding()
}
