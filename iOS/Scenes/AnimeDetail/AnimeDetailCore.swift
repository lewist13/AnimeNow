//
//  AnimeDetailCore.swift
//  Anime Now!
//
//  Created Erik Bautista on 9/6/22.
//  Copyright © 2022. All rights reserved.
//

import Foundation
import ComposableArchitecture

enum AnimeDetailCore {
    typealias LoadableEpisodes = LoadableState<IdentifiedArrayOf<Episode>>
    typealias LoadableAnimeStore = LoadableState<AnimeStore>

    struct State: Equatable {
        let anime: Anime

        var episodes = LoadableEpisodes.idle
        var animeStore = LoadableAnimeStore.idle
    }

    enum Action: Equatable {
        case onAppear
        case tappedFavorite
        case closeButtonPressed
        case close
        case playResumeButtonClicked
        case fetchedEpisodes(Result<[Episode], Never>)
        case selectedEpisode(episode: Episode)
        case play(anime: Anime, episodes: IdentifiedArrayOf<Episode>, selected: Episode.ID)
        case fetchedAnimeFromDB([AnimeStore])
    }

    struct Environment {
        let animeClient: AnimeClient
        let mainQueue: AnySchedulerOf<DispatchQueue>
        let mainRunLoop: AnySchedulerOf<RunLoop>
        let repositoryClient: RepositoryClient
    }
}

extension AnimeDetailCore {
    enum PlayButtonState: Equatable {
        case unavailable
        case comingSoon
        case playFromBeginning(EpisodeInfo)
        case playNextEpisode(EpisodeInfo)
        case resumeEpisode(EpisodeInfo)

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

        struct EpisodeInfo: Equatable {
            let id: Episode.ID
            let format: Anime.Format
            var episodeNumber: Int?
        }
    }
}

extension AnimeDetailCore.State {
    var format: Anime.Format {
        anime.format
    }

    var playButtonState: AnimeDetailCore.PlayButtonState {
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

    var loading: Bool {
        anime.status != .upcoming && !episodes.finished ||
        anime.status != .upcoming && !animeStore.finished
    }
}

extension AnimeDetailCore {
    static var reducer: Reducer<AnimeDetailCore.State, AnimeDetailCore.Action, AnimeDetailCore.Environment> {
        .init { state, action, environment in
            struct CancelFetchingEpisodesId: Hashable {}
            struct CancelFetchingSourcesId: Hashable {}

            switch action {
            case .onAppear:
                guard state.anime.status != .upcoming && !state.episodes.hasInitialized else { break }
                state.episodes = .loading
                state.animeStore = .loading
                return .merge(
                    environment.animeClient.getEpisodes(state.anime.id)
                        .receive(on: environment.mainQueue)
                        .catchToEffect()
                        .map(Action.fetchedEpisodes)
                        .cancellable(id: CancelFetchingEpisodesId()),
                    environment.repositoryClient.observe(.init(format: "id == %d", state.anime.id), [])
                        .receive(on: environment.mainQueue)
                        .eraseToEffect()
                        .map(Action.fetchedAnimeFromDB)
                )
            case .tappedFavorite:
                if var animeStore = state.animeStore.value ?? nil {
                    animeStore.isFavorite.toggle()

                    return environment.repositoryClient.insertOrUpdate(animeStore)
                        .receive(on: environment.mainQueue)
                        .fireAndForget()
                }
            case .playResumeButtonClicked:
                if let episodeId = state.playButtonState.episodeId, let episode = state.episodes.value?[id: episodeId] {
                    return .init(value: .selectedEpisode(episode: episode))
                }
            case .fetchedEpisodes(.success(let episodes)):
                state.episodes = .success(.init(uniqueElements: episodes))
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
                state.animeStore = .success(.findOrCreate(state.anime.id, animesMatched))
            case .play:
                break
            case .closeButtonPressed:
                return .concatenate(
                    .cancel(id: CancelFetchingEpisodesId()),
                    .cancel(id: CancelFetchingSourcesId()),
                    .init(value: .close)
                )
            case .close:
                break
            }
            return .none
        }
    }
}
