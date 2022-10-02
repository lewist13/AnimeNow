//
//  VideoPlayerV2Core.swift
//  Anime Now!
//
//  Created Erik Bautista on 10/1/22.
//  Copyright © 2022. All rights reserved.
//

import Foundation
import ComposableArchitecture

enum VideoPlayerV2Core {
    enum SelectedEpisodeIdentifier: Equatable {
        case id(Episode.ID)
        case number(Int)
    }

    struct State: Equatable {

        let anime: Anime
        var episodes = LoadableState<IdentifiedArrayOf<Episode>>.idle
        var selectedEpisode: SelectedEpisodeIdentifier
        var isOffline = false

        var savedAnimeInfo = LoadableState<AnimeInfoStore>.idle
        var sources = LoadableState<IdentifiedArrayOf<Source>>.idle

        var selectedSource: Source.ID?

//        init(
//            anime: Anime,
//            episodes: [Episode]?,
//            selectedEpisode: SelectedEpisodeIdentifier
//        ) {
//            self.anime = anime
//            self.episodes = episodes != nil ? .success(.init(uniqueElements: episodes!)) : .idle
//            self.selectedEpisode = selectedEpisode
//        }
    }

    enum Action: Equatable {

        // View Actions

        case onAppear
        case backwardsTapped
        case forwardTapped
        case playerTapped

        // Internal Actions

        case initializeFirstTime

        // Fetching

        case fetchEpisodes
        case fetchedEpisodes(Result<[Episode], API.Error>)
        case fetchSources
        case fetchedSources(Result<[Source], API.Error>)
    }

    struct Environment {
        let animeClient: AnimeClient
        let mainQueue: AnySchedulerOf<DispatchQueue>
        let mainRunLoop: AnySchedulerOf<RunLoop>
        let repositoryClient: RepositoryClient
        let userDefaultsClient: UserDefaultsClient
    }
}

// MARK: Loading State

extension VideoPlayerV2Core.State {
    enum LoadingState {
        case fetchingEpisodes
        case fetchingSources
        case buffering
    }

    var loadingState: LoadingState? {
        if !episodes.finished {
            return .fetchingEpisodes
        } else if !sources.finished {
            return .fetchingSources
        }
        return nil
    }
}

// MARK: Error State

extension VideoPlayerV2Core.State {
    enum Error {
        case failedToLoadEpisodes
        case failedToLoadSources
    }

    var error: Error? {
        if case .failed = episodes {
            return .failedToLoadEpisodes
        } else if case .failed = sources {
            return .failedToLoadSources
        }
        return nil
    }
}

extension VideoPlayerV2Core.State {
    fileprivate var episode: Episode? {
        if let episodes = episodes.value {
            switch selectedEpisode {
            case .id(let  id):
                return episodes[id: id]
            case .number(let epNumber):
                return episodes.first(where: { $0.number == epNumber })
            }
        }

        return nil
    }
}

extension VideoPlayerV2Core.State {
    fileprivate var source: Source? {
        if let sourceId = selectedSource, let sources = sources.value {
            return sources[id: sourceId]
        }
        return nil
    }
}

extension VideoPlayerV2Core {
    static var reducer: Reducer<VideoPlayerV2Core.State, VideoPlayerV2Core.Action, VideoPlayerV2Core.Environment> {
        .init { state, action, environment in
            switch action {

            // View Actions

            case .onAppear:
                return .init(value: .fetchEpisodes)
            case .backwardsTapped:
                break
            case .forwardTapped:
                break
            case .playerTapped:
                break

            // Internal Actions

            case .initializeFirstTime:
                return .concatenate(
                    .init(value: .fetchEpisodes)
                )

            // Fetch Episodes

            case .fetchEpisodes:
                guard !state.episodes.hasInitialized else {
                    if state.episode != nil {
                        return .init(value: .fetchSources)
                    }
                    break
                }
                state.episodes = .loading
                return environment.animeClient.getEpisodes(state.anime.id)
                    .receive(on: environment.mainQueue)
                    .catchToEffect()
                    .map(Action.fetchedEpisodes)

            case .fetchedEpisodes(.success(let episodes)):
                state.episodes = .success(.init(uniqueElements: episodes))
                return .init(value: .fetchSources)

            case .fetchedEpisodes(.failure):
                state.episodes = .failed

            // Fetch Sources

            case .fetchSources:
                guard let episode = state.episode else { break }
                state.sources = .loading
                return environment.animeClient.getSources(episode.id)
                    .receive(on: environment.mainQueue)
                    .catchToEffect()
                    .map(Action.fetchedSources)

            case .fetchedSources(.success(let sources)):
                state.sources = .success(.init(uniqueElements: sources))
                state.selectedSource = sources.first(where: { $0.quality == .teneightyp })?.id

            case .fetchedSources(.failure):
                state.sources = .failed
                state.selectedSource = nil

            default:
                break
            }

            return .none
        }
    }
}
