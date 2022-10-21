//
//  HomeCore.swift
//  Anime Now!
//
//  Created by ErrorErrorError on 9/4/22.
//  Copyright © 2022. All rights reserved.
//

import Foundation
import ComposableArchitecture
import SwiftUI

enum HomeCore {
    typealias LoadableAnime = LoadableState<[Anime]>
    typealias LoadableEpisodes = LoadableState<[ResumeWatchingEpisode]>

    struct State: Equatable {
        var topTrendingAnime: LoadableAnime = .idle
        var topUpcomingAnime: LoadableAnime = .idle
        var highestRatedAnime: LoadableAnime = .idle
        var mostPopularAnime: LoadableAnime = .idle
        var resumeWatching: LoadableEpisodes = .idle
        var lastWatchedAnime: LoadableAnime = .idle
    }

    enum Action: Equatable, BindableAction {
        case onAppear
        case animeTapped(Anime)
        case resumeWatchingTapped(ResumeWatchingEpisode)
        case markAsWatched(ResumeWatchingEpisode)
        case fetchedAnime(keyPath: WritableKeyPath<State, LoadableAnime>, result: Result<[Anime], EquatableError>)
        case observingAnimesInDB([AnimeStore])
        case fetchLastWatchedAnimes([Anime.ID])
        case fetchedLastWatchedAnimes([Anime])
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
        !topTrendingAnime.finished ||
        !topUpcomingAnime.finished ||
        !highestRatedAnime.finished ||
        !mostPopularAnime.finished ||
        !resumeWatching.finished ||
        !lastWatchedAnime.finished
    }

    var hasInitialized: Bool {
        topTrendingAnime.hasInitialized &&
        topUpcomingAnime.hasInitialized &&
        highestRatedAnime.hasInitialized &&
        mostPopularAnime.hasInitialized &&
        resumeWatching.hasInitialized &&
        lastWatchedAnime.hasInitialized
    }
}

extension HomeCore {
    static let reducer = Reducer<HomeCore.State, HomeCore.Action, HomeCore.Environment>.combine(
        .init { state, action, environment in
            struct LastWatchAnimesFetchCancellable: Hashable {}
            struct ResumeWatchingFetchAnimeCancellable: Hashable {}

            switch (action) {
            case .onAppear:
                guard !state.hasInitialized else { break }
                state.topTrendingAnime = .loading
                state.topUpcomingAnime = .loading
                state.highestRatedAnime = .loading
                state.mostPopularAnime = .loading
                state.resumeWatching = .loading
                state.lastWatchedAnime = .loading

                return .merge(
                    environment.animeClient.getTopTrendingAnime()
                        .receive(on: environment.mainQueue)
                        .catchToEffect()
                        .map { HomeCore.Action.fetchedAnime(keyPath: \.topTrendingAnime, result: $0) },
                    environment.animeClient.getTopUpcomingAnime()
                        .receive(on: environment.mainQueue)
                        .catchToEffect()
                        .map { HomeCore.Action.fetchedAnime(keyPath: \.topUpcomingAnime, result: $0) },
                    environment.animeClient.getHighestRatedAnime()
                        .receive(on: environment.mainQueue)
                        .catchToEffect()
                        .map { HomeCore.Action.fetchedAnime(keyPath: \.highestRatedAnime, result: $0) },
                    environment.animeClient.getMostPopularAnime()
                        .receive(on: environment.mainQueue)
                        .catchToEffect()
                        .map { HomeCore.Action.fetchedAnime(keyPath: \.mostPopularAnime, result: $0) },
                    environment.repositoryClient.observe(
                        .init(
                            format: "episodeStores.@count > 0"
                        ),
                        [],
                        true
                    )
                        .receive(on: environment.mainQueue)
                        .eraseToEffect()
                        .map(Action.observingAnimesInDB)
                )

            case .fetchedAnime(let keyPath, .success(let anime)):
                state[keyPath: keyPath] = .success(anime)

            case .fetchedAnime(let keyPath, .failure(let error)):
                print(error)
                state[keyPath: keyPath] = .failed

            case .observingAnimesInDB(let animesInDb):
                var lastWatched = [Anime.ID]()
                var resumeWatchingAnimes = [ResumeWatchingEpisode]()

                let sortedAnimeStores = animesInDb.sorted { anime1, anime2 in
                    guard let lastModifiedOne = anime1.lastModifiedEpisode,
                          let lastModifiedTwo = anime2.lastModifiedEpisode else {
                        return false
                    }
                    return lastModifiedOne.lastUpdatedProgress > lastModifiedTwo.lastUpdatedProgress
                }

                for animeStore in sortedAnimeStores {
                    lastWatched.append(animeStore.id)

                    guard let recentEpisodeStore = animeStore.lastModifiedEpisode, !recentEpisodeStore.almostFinished else { continue }
                    resumeWatchingAnimes.append(.init(anime: animeStore, title: animeStore.title, episodeStore: recentEpisodeStore))
                }

                state.resumeWatching = .success(resumeWatchingAnimes)
                return .init(value: .fetchLastWatchedAnimes(sortedAnimeStores.map(\.id)))

            case .fetchLastWatchedAnimes(let animeIds):
                guard !animeIds.isEmpty else {
                    state.lastWatchedAnime = .success([])
                    break
                }

                return environment.animeClient.getAnimes(animeIds)
                    .receive(on: environment.mainQueue)
                    .replaceError(with: [])
                    .eraseToEffect()
                    .map { animes in
                        var sorted = [Anime]()

                        for id in animeIds {
                            if let anime = animes.first(where: { $0.id == id }) {
                                sorted.append(anime)
                            }
                        }
                        return sorted
                    }
                    .map(Action.fetchedLastWatchedAnimes)
                    .cancellable(id: LastWatchAnimesFetchCancellable(), cancelInFlight: true)

            case .fetchedLastWatchedAnimes(let animes):
                state.lastWatchedAnime = .success(animes)

            case .markAsWatched(let resumeWatching):
                var episodeStore = resumeWatching.episodeStore
                episodeStore.progress = 1.0

                return environment.repositoryClient.update(episodeStore)
                    .receive(on: environment.mainQueue)
                    .fireAndForget()

            case .resumeWatchingTapped:
                break

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

extension HomeCore {
    struct ResumeWatchingEpisode: Equatable, Identifiable {
        var id: AnimeStore.ID { anime.id }
        let anime: AnimeStore
        let title: String
        let episodeStore: EpisodeStore
    }
}
