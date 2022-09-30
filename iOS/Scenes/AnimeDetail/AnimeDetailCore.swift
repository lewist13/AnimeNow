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
    typealias LoadableEpisodeProgress = LoadableState<IdentifiedArrayOf<EpisodeProgress>>

    struct State: Equatable {
        let anime: Anime

        var episodes = LoadableEpisodes.idle
        var episodesProgress = LoadableEpisodeProgress.idle
        var moreInfo = Set<Episode.ID>()
    }

    enum Action: Equatable {
        case onAppear
        case closeButtonPressed
        case close
        case playResumeButtonClicked
        case fetchedEpisodes(Result<[Episode], API.Error>)
        case selectedEpisode(episode: Episode)
        case play(anime: Anime, episodes: IdentifiedArrayOf<Episode>, selected: Episode.ID)
        case moreInfo(id: Episode.ID)
        case fetchedEpisodesProgress([EpisodeProgress])
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
        if anime.status == .upcoming {
            return .comingSoon
        } else if case let .success(episodes) = episodes, case let .success(episodesProgress) = episodesProgress, episodes.count > 0 {
            let lastUpdatedProgress = episodesProgress.sorted(by: { $0.lastUpdated > $1.lastUpdated }).first
            if let lastUpdatedProgress = lastUpdatedProgress, 0.9 > lastUpdatedProgress.progress && lastUpdatedProgress.progress > 0 {
                return .resumeEpisode(
                    .init(
                        id: lastUpdatedProgress.id.episodeId,
                        format: anime.format,
                        episodeNumber: anime.format == .movie ? nil : Int(lastUpdatedProgress.episodeNumber)
                    )
                )
            } else if let lastUpdatedProgress = lastUpdatedProgress,
                      let lastEpisode = episodes.last,
                      lastEpisode.id != lastUpdatedProgress.id.episodeId,
                      let lastUpdatedProgressInx = episodes.index(id: lastUpdatedProgress.id.episodeId) {
                let nextEpisode = episodes[episodes.index(after: lastUpdatedProgressInx)]
                return .playNextEpisode(
                    .init(
                        id: nextEpisode.id,
                        format: anime.format,
                        episodeNumber: anime.format == .movie ? nil : nextEpisode.number
                    )
                )
            } else if let episode = episodes.first {
                return .playFromBeginning(
                    .init(
                        id: episode.id,
                        format: anime.format,
                        episodeNumber: anime.format == .movie ? nil : episode.number
                    )
                )
            }
        }
        return .unavailable
    }

    var loading: Bool {
        episodes == .loading || anime.status != .upcoming && !episodes.hasInitialized || !episodesProgress.finished
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
                state.episodesProgress = .loading
                return .merge(
                    environment.animeClient.getEpisodes(state.anime.id)
                        .receive(on: environment.mainQueue)
                        .catchToEffect()
                        .map(Action.fetchedEpisodes)
                        .cancellable(id: CancelFetchingEpisodesId()),
                    environment.repositoryClient.observe(
                        .init(format: "id.animeId == %d", state.anime.id),
                        []
                    )
                    .receive(on: environment.mainQueue)
                    .eraseToEffect()
                    .map(Action.fetchedEpisodesProgress)
                )
            case .playResumeButtonClicked:
                if let episodeId = state.playButtonState.episodeId, let episode = state.episodes.value?[id: episodeId] {
                    return .init(value: .selectedEpisode(episode: episode))
                }
            case .fetchedEpisodes(.success(let episodes)):
                state.episodes = .success(.init(uniqueElements: episodes))
            case .fetchedEpisodes(.failure):
                state.episodes = .failed
            case .moreInfo(id: let id):
               if state.moreInfo.contains(id) {
                   state.moreInfo.remove(id)
               } else {
                   state.moreInfo.insert(id)
               }
            case .selectedEpisode(episode: let episode):
                return .init(
                    value: .play(
                        anime: state.anime,
                        episodes: state.episodes.value ?? [],
                        selected: episode.id
                    )
                )
            case .fetchedEpisodesProgress(let episodesProgress):
                state.episodesProgress = .success(.init(uniqueElements: episodesProgress))
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
