//
//  AnimeDetailReducer.swift
//  Anime Now!
//
//  Created by ErrorErrorError on 9/6/22.
//  Copyright © 2022. All rights reserved.
//

import Foundation
import ComposableArchitecture

struct AnimeDetailReducer: ReducerProtocol {
    typealias LoadableEpisodes = Loadable<[Episode]>
    typealias LoadableAnimeStore = Loadable<AnimeStore>

    struct State: Equatable {
        let anime: Anime

        var episodes = LoadableEpisodes.idle
        var animeStore = LoadableAnimeStore.idle

        var compactEpisodes = false
    }

    enum Action: Equatable {
        case onAppear
        case tappedFavorite
        case tappedInWatchlist
        case closeButtonPressed
        case close
        case playResumeButtonClicked
        case toggleCompactEpisodes
        case fetchedEpisodes(TaskResult<[Episode]>)
        case selectedEpisode(episode: Episode)
        case play(anime: Anime, episodes: [Episode], selected: Episode.ID)
        case fetchedAnimeFromDB([AnimeStore])
    }

    @Dependency(\.animeClient) var animeClient
    @Dependency(\.mainQueue) var mainQueue
    @Dependency(\.repositoryClient) var repositoryClient
    @Dependency(\.userDefaultsClient) var userDefaultsClient
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
    var format: Anime.Format {
        anime.format
    }

    var playButtonState: AnimeDetailReducer.PlayButtonState {
        guard anime.status != .upcoming else {
            return .comingSoon
        }

        guard let episodes = episodes.value,
              !episodes.isEmpty,
              let firstEpisode = episodes.first else {
            return .unavailable
        }

        let episodesProgress = animeStore.value?.episodeStores
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
        anime.status != .upcoming && !episodes.finished ||
        anime.status != .upcoming && !animeStore.finished
    }
}

extension AnimeDetailReducer {
    @ReducerBuilder<State, Action>
    var body: Reduce<State, Action> {
        Reduce(self.core)
    }

    struct CancelAnimeFetchingId: Hashable {}
    struct CancelFetchingEpisodesId: Hashable {}
    struct CancelObservingAnimeDB: Hashable {}

    func core(state: inout State, action: Action) -> EffectTask<Action> {
        switch action {
        case .onAppear:
            state.compactEpisodes = userDefaultsClient.boolForKey(.compactEpisodes)

            guard state.anime.status != .upcoming && !state.episodes.hasInitialized else { break }
            state.episodes = .loading
            state.animeStore = .loading

            let animeId = state.anime.id
            return .merge(
                .run {
                    await .fetchedEpisodes(.init { try await animeClient.getEpisodes(animeId) })
                }
                    .cancellable(id: CancelFetchingEpisodesId.self),
                .run { [state] send in
                    let animeStoresStream: AsyncStream<[AnimeStore]> = repositoryClient.observe(.init(format: "id == %d", state.anime.id))

                    for try await animeStores in animeStoresStream {
                        await send(.fetchedAnimeFromDB(animeStores))
                    }
                }
                    .cancellable(id: CancelObservingAnimeDB.self)
            )

        case .tappedFavorite:
            if var animeStore = state.animeStore.value {
                animeStore.isFavorite.toggle()

                return .fireAndForget { [animeStore] in
                    _ = try await repositoryClient.insertOrUpdate(animeStore)
                }
            }

        case .tappedInWatchlist:
            if var animeStore = state.animeStore.value {
                animeStore.inWatchlist.toggle()

                return .fireAndForget { [animeStore] in
                    _ = try await repositoryClient.insertOrUpdate(animeStore)
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
            return .init(
                value: .play(
                    anime: state.anime,
                    episodes: state.episodes.value ?? [],
                    selected: episode.id
                )
            )

        case .fetchedAnimeFromDB(let animesMatched):
            state.animeStore = .success(.findOrCreate(state.anime, animesMatched))

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
                .action(.close)
            )

        case .close:
            break
        }
        return .none
    }
}
