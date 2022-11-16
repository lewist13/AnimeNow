//
//  AnimeDetailReducer.swift
//  Anime Now!
//
//  Created by ErrorErrorError on 9/6/22.
//  Copyright © 2022. All rights reserved.
//

import Foundation
import Sworm
import ComposableArchitecture

struct AnimeDetailReducer: ReducerProtocol {
    typealias LoadableEpisodes = Loadable<[Episode]>
    typealias LoadableAnimeStore = Loadable<AnimeStore>
    typealias LoadableCollectionStores = Loadable<[CollectionStore]>

    struct State: Equatable {
        let animeId: Anime.ID

        var anime: Loadable<Anime> = .idle
        var episodes = LoadableEpisodes.idle
        var animeStore = LoadableAnimeStore.idle
        var collectionStores = LoadableCollectionStores.idle

        var compactEpisodes = false

        init(
            anime: some AnimeRepresentable,
            episodes: LoadableEpisodes = .idle,
            animeStore: LoadableAnimeStore = .idle,
            compactEpisodes: Bool = false
        ) {
            self.animeId = anime.id
            if let anime = anime as? Anime {
                self.anime = .success(anime)
            } else {
                self.anime = .idle
            }
            self.episodes = episodes
            self.compactEpisodes = compactEpisodes
        }
    }

    enum Action: Equatable {
        case onAppear
        case tappedFavorite
        case addToCollectionToggle
        case closeButtonPressed
        case close
        case playResumeButtonClicked
        case toggleCompactEpisodes
        case fetchedEpisodes(TaskResult<[Episode]>)
        case fetchedAnime(TaskResult<Anime>)
        case selectedEpisode(episode: Episode)
        case play(anime: Anime, episodes: [Episode], selected: Episode.ID)
        case fetchedAnimeFromDB([AnimeStore])
        case fetchedCollectionStores([CollectionStore])
    }

    @Dependency(\.animeClient) var animeClient
    @Dependency(\.mainQueue) var mainQueue
    @Dependency(\.repositoryClient) var repositoryClient
    @Dependency(\.userDefaultsClient) var userDefaultsClient

    var body: some ReducerProtocol<State, Action> {
        Reduce(self.core)
    }
}

extension AnimeDetailReducer {
    enum PlayButtonState: Equatable {
        case unavailable
        case comingSoon
        case playFromBeginning(EpisodePlayback)
        case playNextEpisode(EpisodePlayback)
        case resumeEpisode(EpisodePlayback)

        var isAvailable: Bool {
            switch self {
            case .unavailable, .comingSoon:
                return false
            default:
                return true
            }
        }

        var episodeId: Episode.ID? {
            switch self {
            case .playFromBeginning(let info), .playNextEpisode(let info), .resumeEpisode(let info):
                return info.id
            default:
                return nil
            }
        }

        var stringValue: String {
            switch self {
            case .unavailable:
                return "Unavailable"
            case .comingSoon:
                return "Coming Soon"
            case .playFromBeginning(let info):
                return "Play \(info.format == .movie ? "Movie" : "")"
            case .playNextEpisode(let info):
                return "Play E\(info.episodeNumber ?? 0)"
            case .resumeEpisode(let info):
                if info.format == .movie {
                    return "Resume Movie"
                } else {
                    return "Resume E\(info.episodeNumber ?? 0)"
                }
            }
        }

        struct EpisodePlayback: Equatable {
            let id: Episode.ID
            let format: Anime.Format
            var episodeNumber: Int?
        }
    }
}

extension AnimeDetailReducer.State {
    var playButtonState: AnimeDetailReducer.PlayButtonState {
        guard let anime = anime.value else {
            return .unavailable
        }

        guard anime.status != .upcoming else {
            return .comingSoon
        }

        guard let episodes = episodes.value,
              let firstEpisode = episodes.first else {
            return .unavailable
        }

        let episodesProgress = animeStore.value?.episodes
        let lastUpdatedProgress = episodesProgress?.sorted(by: \.lastUpdatedProgress).last

        if let lastUpdatedProgress = lastUpdatedProgress,
           let episode = episodes.first(where: { $0.number == lastUpdatedProgress.number }) {
            if !lastUpdatedProgress.almostFinished {
                return .resumeEpisode(
                    .init(
                        id: episode.id,
                        format: anime.format,
                        episodeNumber: episode.number
                    )
                )
            } else if lastUpdatedProgress.almostFinished,
                      episodes.last != episode,
                      let nextEpisode = episodes.first(where: { $0.number == (lastUpdatedProgress.number + 1) }) {
                return .playNextEpisode(
                    .init(
                        id: nextEpisode.id,
                        format: anime.format,
                        episodeNumber: nextEpisode.number
                    )
                )
            }
        }

        return .playFromBeginning(
            .init(
                id: firstEpisode.id,
                format: anime.format,
                episodeNumber: firstEpisode.number
            )
        )
    }

    var isLoading: Bool {
        guard let anime = anime.value else { return !anime.finished }
        return anime.status != .upcoming && (!episodes.finished || !animeStore.finished || !collectionStores.finished)
    }

    var isInACollection: Bool {
        guard let collections = collectionStores.value else { return false }
        return collections.contains(where: { $0.animes.contains(where: { animeStore in animeStore.id == animeId }) } )
    }
}

extension AnimeDetailReducer {
    struct CancelAnimeFetchingId: Hashable {}
    struct CancelFetchingEpisodesId: Hashable {}
    struct CancelObservingAnimeDB: Hashable {}
    struct CancelObservingCollections: Hashable {}
    struct AddToCollectionDebounce: Hashable {}
    struct FavoritesDebouce: Hashable {}

    func core(state: inout State, action: Action) -> EffectTask<Action> {
        switch action {
        case .onAppear:
            state.compactEpisodes = userDefaultsClient.boolForKey(.compactEpisodes)

            guard state.anime.value != nil else {
                if !state.anime.hasInitialized {
                    return self.fetchAnime(&state)
                }
                break
            }

            return self.fetchEpisodesAndStore(&state)

        case .tappedFavorite:
            guard var animeStore = state.animeStore.value else { break }
            animeStore.isFavorite.toggle()

            return .run { [animeStore] in
                try await withTaskCancellation(id: FavoritesDebouce.self, cancelInFlight: true) {
                    _ = try await repositoryClient.insert(animeStore)
                }
            }

        case .addToCollectionToggle:
            guard let animeStore = state.animeStore.value else { break }
            guard let collectionStores = state.collectionStores.value else { break }

            return .run { _ in
                try await withTaskCancellation(
                    id: AddToCollectionDebounce.self,
                    cancelInFlight: true
                ) {
                    if var plannedCollections = collectionStores.first(where: { $0.title == .planning }) {
                        if !plannedCollections.animes.contains(where: { $0.id == animeStore.id }) {
                            plannedCollections.animes.append(animeStore)
                        } else {
                            plannedCollections.animes.removeAll { anime in
                                anime.id == animeStore.id
                            }
                        }
                        _ = try await repositoryClient.insert(plannedCollections)
                    }
                }
            }

        case .playResumeButtonClicked:
            if let episodeId = state.playButtonState.episodeId, let episode = state.episodes.value?[id: episodeId] {
                return .action(.selectedEpisode(episode: episode))
            }

        case .fetchedEpisodes(.success(let episodes)):
            state.episodes = .success(episodes)

        case .fetchedEpisodes(.failure(let error)):
            print(error)
            state.episodes = .failed

        case .selectedEpisode(episode: let episode):
            guard let anime = state.anime.value else { break }
            return .init(
                value: .play(
                    anime: anime,
                    episodes: state.episodes.value ?? [],
                    selected: episode.id
                )
            )
        case .fetchedAnime(.success(let anime)):
            state.anime = .success(anime)
            return self.fetchEpisodesAndStore(&state)

        case .fetchedAnime(.failure):
            state.anime = .failed

        case .fetchedAnimeFromDB(let animesMatched):
            guard let anime = state.anime.value else { break }
            state.animeStore = .success(.findOrCreate(anime, animesMatched))

        case .fetchedCollectionStores(let collectionStores):
            state.collectionStores = .success(collectionStores)

        case .toggleCompactEpisodes:
            state.compactEpisodes.toggle()

            return .run { [state] in
                await userDefaultsClient.setBool(.compactEpisodes, state.compactEpisodes)
            }

        case .play:
            break

        case .closeButtonPressed:
            return .concatenate(
                .cancel(id: CancelAnimeFetchingId.self),
                .cancel(id: CancelFetchingEpisodesId.self),
                .cancel(id: CancelObservingAnimeDB.self),
                .cancel(id: CancelObservingCollections.self),
                .action(.close)
            )

        case .close:
            break
        }
        return .none
    }

    private func fetchAnime(_ state: inout State) -> EffectTask<Action> {
        let animeId = state.animeId
        state.anime = .loading

        return .run { send in
            await withTaskCancellation(id: CancelAnimeFetchingId.self, cancelInFlight: true) {
                await send(.fetchedAnime(.init { try await animeClient.getAnime(animeId) }))
            }
        }
    }

    private func fetchEpisodesAndStore(_ state: inout State) -> EffectTask<Action> {
        guard let anime = state.anime.value else { return .none }
        let animeId = anime.id
        var effects = [EffectTask<Action>]()

        if anime.status != .upcoming && !state.episodes.hasInitialized {
            state.episodes = .loading

            effects.append(
                .run {
                    await .fetchedEpisodes(.init { try await animeClient.getEpisodes(animeId) })
                }
                    .cancellable(id: CancelFetchingEpisodesId.self)
            )
        }

        if !state.animeStore.hasInitialized {
            state.animeStore = .loading

            effects.append(
                .run { send in
                    let animeStoresStream: AsyncStream<[AnimeStore]> = repositoryClient.observe(
                        AnimeStore.all.where(\AnimeStore.id == animeId)
                    )

                    for try await animeStores in animeStoresStream {
                        await send(.fetchedAnimeFromDB(animeStores))
                    }
                }
                    .cancellable(id: CancelObservingAnimeDB.self)
            )
        }

        if !state.collectionStores.hasInitialized {
            state.collectionStores = .loading

            effects.append(
                .run { send in
                    let collectionStores: AsyncStream<[CollectionStore]> = repositoryClient.observe(
                        CollectionStore.all
                    )

                    for try await collection in collectionStores {
                        await send(.fetchedCollectionStores(collection))
                    }
                }
                    .cancellable(id: CancelObservingCollections.self)
            )
        }

        return .merge(effects)
    }
}
