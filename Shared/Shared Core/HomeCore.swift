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
    typealias LoadableEpisodes = LoadableState<IdentifiedArrayOf<EpisodeInfoWithAnime>>

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
        case resumeWatchingTapped(EpisodeInfoWithAnime)
        case fetchedAnime(keyPath: WritableKeyPath<State, LoadableAnime>, result: Result<[Anime], EquatableError>)
        case fetchedAnimesInDB([AnimeStore])
        case fetchResumeWatchingAnimes([EpisodeInfoWithAnimeId])
        case fetchedResumeWatchingAnimes(Result<[EpisodeInfoWithAnime], EquatableError>)
        case fetchLastWatchedAnimes([AnimeStore])
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
                            format: "episodeStores.@count > 0"),
                            []
                    )
                        .receive(on: environment.mainQueue)
                        .eraseToEffect()
                        .map(Action.fetchedAnimesInDB)
                )
            case .fetchedAnime(let keyPath, .success(let anime)):
                state[keyPath: keyPath] = .success(.init(uniqueElements: anime))
            case .fetchedAnime(let keyPath, .failure(let error)):
                print(error)
                state[keyPath: keyPath] = .failed

            case .fetchedAnimesInDB(let animesInDb):
                let sortedAnimeStores = animesInDb.sorted { anime1, anime2 in
                    guard let lastModifiedOne = anime1.lastModifiedEpisode,
                          let lastModifiedTwo = anime2.lastModifiedEpisode else {
                        return false
                    }
                    return lastModifiedOne.lastUpdatedProgress > lastModifiedTwo.lastUpdatedProgress
                }

                var resumeWatchingAnimes = [EpisodeInfoWithAnimeId]()
                for animeStore in sortedAnimeStores {
                    guard let recentEpisodeInfo = animeStore.lastModifiedEpisode, !recentEpisodeInfo.almostFinished else { continue }
                    resumeWatchingAnimes.append(.init(animeId: animeStore.id, episodeInfo: recentEpisodeInfo))
                }

                return .merge(
                    .init(value: .fetchLastWatchedAnimes(sortedAnimeStores)),
                    .init(value: .fetchResumeWatchingAnimes(resumeWatchingAnimes))
                )

            case .fetchResumeWatchingAnimes(let episodeInfoWithAnimeIds):
                guard episodeInfoWithAnimeIds.count > 0 else {
                    state.resumeWatching = .success([])
                    break
                }

                return environment.animeClient.getAnimes(episodeInfoWithAnimeIds.map(\.animeId))
                    .receive(on: environment.mainQueue)
                    .catchToEffect()
                    .map {
                        $0.map { animes -> [EpisodeInfoWithAnime] in
                            var episodeInfosWithAnimes = [EpisodeInfoWithAnime]()

                            for anime in animes {
                                if let episodeInfo = episodeInfoWithAnimeIds.first(where: { $0.animeId == anime.id })?.episodeInfo {
                                    episodeInfosWithAnimes.append(.init(anime: anime, episodeInfo: episodeInfo))
                                }
                            }
                            return episodeInfosWithAnimes.sorted(by: \.episodeInfo.lastUpdatedProgress).reversed()
                        }
                    }
                    .map(Action.fetchedResumeWatchingAnimes)
                    .cancellable(id: ResumeWatchingFetchAnimeCancellable(), cancelInFlight: true)

            case .fetchedResumeWatchingAnimes(.success(let resumeWatchings)):
                state.resumeWatching = .success(.init(uniqueElements: resumeWatchings))

            case .fetchedResumeWatchingAnimes(.failure):
                state.resumeWatching = .success([])

            case .fetchLastWatchedAnimes(let animeStores):
                guard !animeStores.isEmpty else {
                    state.lastWatchedAnime = .success([])
                    break
                }

                // TODO: Improve fetching last watched by reducing calls

                return environment.animeClient.getAnimes(animeStores.map(\.id))
                    .receive(on: environment.mainQueue)
                    .replaceError(with: [])
                    .eraseToEffect()
                    .map { animes in
                        var sorted = [Anime]()

                        for animeStore in animeStores {
                            if let anime = animes.first(where: { $0.id == animeStore.id }) {
                                sorted.append(anime)
                            }
                        }
                        return sorted
                    }
                    .map(Action.fetchedLastWatchedAnimes)
                    .cancellable(id: LastWatchAnimesFetchCancellable(), cancelInFlight: true)

            case .fetchedLastWatchedAnimes(let animes):
                state.lastWatchedAnime = .success(.init(uniqueElements: animes))

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
    struct EpisodeInfoWithAnimeId: Equatable {
        let animeId: Anime.ID
        let episodeInfo: EpisodeStore
    }

    struct EpisodeInfoWithAnime: Identifiable, Hashable {
        var id: Anime.ID { anime.id }
        let anime: Anime
        let episodeInfo: EpisodeStore
    }
}
