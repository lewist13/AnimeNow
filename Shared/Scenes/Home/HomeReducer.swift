//
//  HomeReducer.swift
//  Anime Now!
//
//  Created by ErrorErrorError on 9/4/22.
//  Copyright © 2022. All rights reserved.
//

import SwiftUI
import Foundation
import ComposableArchitecture

struct HomeReducer: ReducerProtocol {
    typealias LoadableAnime = Loadable<[Anime]>
    typealias LoadableEpisodes = Loadable<[ResumeWatchingEpisode]>

    struct State: Equatable {
        var topTrendingAnime: LoadableAnime = .idle
        var topUpcomingAnime: LoadableAnime = .idle
        var highestRatedAnime: LoadableAnime = .idle
        var mostPopularAnime: LoadableAnime = .idle
        var resumeWatching: LoadableEpisodes = .idle
        var lastWatchedAnime: Loadable<[AnyAnimeRepresentable]> = .idle
    }

    enum Action: Equatable, BindableAction {
        case onAppear
        case retryFetchingContent
        case animeTapped(Anime)
        case anyAnimeTapped(AnyAnimeRepresentable)
        case resumeWatchingTapped(ResumeWatchingEpisode)
        case markAsWatched(ResumeWatchingEpisode)
        case fetchedAnime(keyPath: WritableKeyPath<State, LoadableAnime>, result: TaskResult<[Anime]>)
        case observingAnimesInDB([AnimeStore])
        case setResumeWatchingEpisodes(LoadableEpisodes)
        case setLastWatchedAnimes([AnyAnimeRepresentable])
        case binding(BindingAction<HomeReducer.State>)
    }

    @Dependency(\.mainQueue) var mainQueue
    @Dependency(\.mainRunLoop) var mainRunLoop
    @Dependency(\.animeClient) var animeClient
    @Dependency(\.repositoryClient) var repositoryClient

    var body: some ReducerProtocol<State, Action> {
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

        if topTrendingAnime == .failed ||
            topUpcomingAnime == .failed ||
            highestRatedAnime == .failed ||
            mostPopularAnime == .failed ||
            resumeWatching == .failed ||
            lastWatchedAnime == .failed {
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

    func core(state: inout State, action: Action) -> EffectTask<Action> {
        switch (action) {
        case .onAppear:
            guard !state.hasInitialized else { break }
            state.resumeWatching = .loading
            state.lastWatchedAnime = .loading

            return .merge(
                self.fetchForContent(state: &state),
                .run { send in
                    let animeStoresStream: AsyncStream<[AnimeStore]> = repositoryClient.observe(
                        AnimeStore.all
                    )

                    for await animeStores in animeStoresStream {
                        await send(.observingAnimesInDB(animeStores))
                    }
                }
            )

        case .retryFetchingContent:
            return self.fetchForContent(state: &state)

        case .fetchedAnime(let keyPath, .success(let anime)):
            state[keyPath: keyPath] = .success(anime)

        case .fetchedAnime(let keyPath, .failure(let error)):
            print(error)
            state[keyPath: keyPath] = .failed

        case .observingAnimesInDB(let animesInDb):
            return .run { send in
                var lastWatched = [Anime.ID]()
                var resumeWatchingEpisodes = [ResumeWatchingEpisode]()

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
                    resumeWatchingEpisodes.append(.init(animeStore: animeStore, title: animeStore.title, episodeStore: recentEpisodeStore))
                }

                await send(.setResumeWatchingEpisodes(.success(resumeWatchingEpisodes)), animation: .easeInOut(duration: 0.25))
                await send(.setLastWatchedAnimes(sortedAnimeStores.compactMap { $0.episodes.count > 0 ? $0.eraseAsRepresentable() : nil }))
            }

        case .setResumeWatchingEpisodes(let episodes):
            state.resumeWatching = episodes

        case .setLastWatchedAnimes(let animes):
            state.lastWatchedAnime = .success(animes)

        case .markAsWatched(let resumeWatching):
            var episodeStore = resumeWatching.episodeStore
            episodeStore.progress = 1.0

            return .run { [episodeStore] in
                _ = try await self.repositoryClient.insert(episodeStore)
            }

        case .resumeWatchingTapped:
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
            }
        )
    }
}

extension HomeReducer {
    struct ResumeWatchingEpisode: Equatable, Identifiable {
        var id: Anime.ID { animeStore.id }
        let animeStore: AnimeStore
        let title: String
        let episodeStore: EpisodeStore
    }
}
