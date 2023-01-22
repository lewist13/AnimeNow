//
//  HomeReducer.swift
//  Anime Now!
//
//  Created by ErrorErrorError on 9/4/22.
//  Copyright © 2022. All rights reserved.
//

import Logger
import SwiftUI
import Utilities
import Foundation
import AnimeClient
import SharedModels
import DatabaseClient
import ComposableArchitecture

public struct HomeReducer: ReducerProtocol {
    public typealias LoadableAnime = Loadable<[Anime]>
    public typealias LoadableWatchAnimeEpisodes = Loadable<[AnyWatchAnimeEpisode]>

    public struct State: Equatable {
        var topTrendingAnime: LoadableAnime = .idle
        var recentlyUpdated: LoadableWatchAnimeEpisodes = .idle
        var topUpcomingAnime: LoadableAnime = .idle
        var highestRatedAnime: LoadableAnime = .idle
        var mostPopularAnime: LoadableAnime = .idle
        var resumeWatching: LoadableWatchAnimeEpisodes = .idle
        var lastWatchedAnime: Loadable<[AnyAnimeRepresentable]> = .idle

        public init(
            topTrendingAnime: HomeReducer.LoadableAnime = .idle,
            recentlyUpdated: LoadableWatchAnimeEpisodes = .idle,
            topUpcomingAnime: HomeReducer.LoadableAnime = .idle,
            highestRatedAnime: HomeReducer.LoadableAnime = .idle,
            mostPopularAnime: HomeReducer.LoadableAnime = .idle,
            resumeWatching: HomeReducer.LoadableWatchAnimeEpisodes = .idle,
            lastWatchedAnime: Loadable<[AnyAnimeRepresentable]> = .idle
        ) {
            self.topTrendingAnime = topTrendingAnime
            self.recentlyUpdated = recentlyUpdated
            self.topUpcomingAnime = topUpcomingAnime
            self.highestRatedAnime = highestRatedAnime
            self.mostPopularAnime = mostPopularAnime
            self.resumeWatching = resumeWatching
            self.lastWatchedAnime = lastWatchedAnime
        }
    }

    public enum Action: Equatable, BindableAction {
        case onAppear
        case retryFetchingContent
        case animeTapped(Anime)
        case anyAnimeTapped(id: Anime.ID)
        case watchEpisodeTapped(AnyWatchAnimeEpisode)
        case markAsWatched(AnyWatchAnimeEpisode)
        case fetchedRecentlyUpdated(Loadable<[UpdatedAnimeEpisode]>)
        case fetchedAnime(keyPath: WritableKeyPath<State, LoadableAnime>, result: LoadableAnime)
        case observingAnimesInDB([AnimeStore])
        case setResumeWatchingEpisodes(LoadableWatchAnimeEpisodes)
        case setLastWatchedAnimes([AnyAnimeRepresentable])
        case binding(BindingAction<HomeReducer.State>)
    }

    @Dependency(\.mainQueue) var mainQueue
    @Dependency(\.mainRunLoop) var mainRunLoop
    @Dependency(\.animeClient) var animeClient
    @Dependency(\.databaseClient) var databaseClient

    public init() { }

    public var body: some ReducerProtocol<State, Action> {
        Reduce(self.core)
    }
}

extension HomeReducer.State {
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

    enum Error: Equatable {
        case failedToLoad
        case notConnectedToInternet

        var title: String {
            switch self {
            case .failedToLoad:
               return "Failed to Load Content."
            case .notConnectedToInternet:
                return "No Internet Connectioin"
            }
        }

        var description: String? {
            return nil
        }

        var image: Image? {
            switch self {
            case .notConnectedToInternet:
                return .init(systemName: "wifi.slash")
            default:
                return .init(systemName: "exclamationmark.triangle.fill")
            }
        }

        var action: (String, HomeReducer.Action)? {
            switch self {
            case .notConnectedToInternet,
                    .failedToLoad:
                return ("Retry", .retryFetchingContent)
            }
        }
    }

    var error: Error? {
        guard !isLoading else { return nil }

        if topTrendingAnime.failed ||
            topUpcomingAnime.failed ||
            highestRatedAnime.failed ||
            mostPopularAnime.failed ||
            resumeWatching.failed ||
            lastWatchedAnime.failed {
            return .failedToLoad
        }
        return nil
    }
}

extension HomeReducer {
    struct FetchTopTrendingCancellable: Hashable {}
    struct FetchTopUpcomingCancellable: Hashable {}
    struct FetchHighestRatedCancellable: Hashable {}
    struct FetchMostPopularCancellable: Hashable {}
    struct FetchLatestUpdatedCancellable: Hashable {}

    func core(state: inout State, action: Action) -> EffectTask<Action> {
        switch (action) {
        case .onAppear:
            guard !state.hasInitialized else { break }
            state.resumeWatching = .loading
            state.lastWatchedAnime = .loading

            return .merge(
                self.fetchForContent(state: &state),
                .run { send in
                    let animeStoresStream: AsyncStream<[AnimeStore]> = databaseClient.observe(
                        AnimeStore.all
                    )

                    for await animeStores in animeStoresStream {
                        await send(.observingAnimesInDB(animeStores))
                    }
                }
            )

        case .retryFetchingContent:
            return self.fetchForContent(state: &state)

        case .fetchedAnime(let keyPath, let result):
            state[keyPath: keyPath] = result

        case .observingAnimesInDB(let animesInDb):
            return .run { send in
                var lastWatched = [Anime.ID]()
                var resumeWatchingEpisodes = [AnyWatchAnimeEpisode]()

                let sortedAnimeStores = animesInDb.filter { $0.lastModifiedEpisode != nil }
                    .sorted { anime1, anime2 in
                    guard let lastModifiedOne = anime1.lastModifiedEpisode,
                          let lastModifiedTwo = anime2.lastModifiedEpisode else {
                        return false
                    }
                    return lastModifiedOne.lastUpdatedProgress > lastModifiedTwo.lastUpdatedProgress
                }

                for animeStore in sortedAnimeStores {
                    lastWatched.append(animeStore.id)

                    guard let episode = animeStore.lastModifiedEpisode, !episode.almostFinished, (episode.progress ?? 0 > 0) else { continue }
                    resumeWatchingEpisodes.append(
                        .init(
                            anime: animeStore.eraseAsRepresentable(),
                            episode: episode.eraseAsRepresentable(),
                            episodeStore: episode
                        )
                    )
                }

                await send(.setResumeWatchingEpisodes(.success(resumeWatchingEpisodes)), animation: .easeInOut(duration: 0.25))
                await send(.setLastWatchedAnimes(sortedAnimeStores.map { $0.eraseAsRepresentable() }))
            }

        case .fetchedRecentlyUpdated(let result):
            state.recentlyUpdated = result
                .map { list in
                    list.map({
                        .init(
                            anime: $0.anime.eraseAsRepresentable(),
                            episode: $0.episode.eraseAsRepresentable(),
                            episodeStore: nil
                        )
                        
                    })
                }

        case .setResumeWatchingEpisodes(let episodes):
            state.resumeWatching = episodes

        case .setLastWatchedAnimes(let animes):
            state.lastWatchedAnime = .success(animes)

        case .markAsWatched(let resumeWatching):
            if let episodeStore = resumeWatching.episodeStore {
                return .run { _ in
                    try await self.databaseClient.update(episodeStore.id, \EpisodeStore.progress, 1.0)
                }
            }

        case .watchEpisodeTapped:
            break

        case .binding:
            break

        case .animeTapped, .anyAnimeTapped:
            break
        }

        return .none
    }

    func fetchForContent(state: inout State) -> EffectTask<Action> {
        state.topTrendingAnime = .loading
        state.topUpcomingAnime = .loading
        state.highestRatedAnime = .loading
        state.mostPopularAnime = .loading
        state.recentlyUpdated = .loading

        return .merge(
            .run {
                await withTaskCancellation(id: FetchTopTrendingCancellable.self, cancelInFlight: true) {
                    await .fetchedAnime(
                        keyPath: \.topTrendingAnime,
                        result: .init { try await animeClient.getTopTrendingAnime() }
                    )
                }
            },
            .run {
                await withTaskCancellation(id: FetchTopUpcomingCancellable.self, cancelInFlight: true) {
                    await .fetchedAnime(
                        keyPath: \.topUpcomingAnime,
                        result: .init { try await animeClient.getTopUpcomingAnime() }
                    )
                }
            },
            .run {
                await withTaskCancellation(id: FetchHighestRatedCancellable.self, cancelInFlight: true) {
                    await .fetchedAnime(
                        keyPath: \.highestRatedAnime,
                        result: .init { try await animeClient.getHighestRatedAnime() }
                    )
                }
            },
            .run {
                await withTaskCancellation(id: FetchMostPopularCancellable.self, cancelInFlight: true) {
                    await .fetchedAnime(
                        keyPath: \.mostPopularAnime,
                        result: .init { try await animeClient.getMostPopularAnime() }
                    )
                }
            },
            .run {
                await withTaskCancellation(id: FetchLatestUpdatedCancellable.self, cancelInFlight: true) {
                    await .fetchedRecentlyUpdated(
                        .init { try await animeClient.getRecentlyUpdated() }
                    )
                }
            }
        )
    }
}

extension HomeReducer {
    public struct AnyWatchAnimeEpisode: Equatable, Identifiable {
        public var id: String { "\(anime.id)-\(episode.number)" }
        public let anime: AnyAnimeRepresentable
        public let episode: AnyEpisodeRepresentable
        public let episodeStore: EpisodeStore?
    }
}
