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
    enum Sidebar {
        case episodes
        case providers
        case subtitles
    }

    struct State: Equatable {
        let anime: Anime

        var episodes = LoadableState<IdentifiedArrayOf<Episode>>.idle
        var sources = LoadableState<IdentifiedArrayOf<Source>>.idle
        var savedAnimeInfo = LoadableState<AnimeInfoStore>.idle

        var selectedEpisode: Episode.ID
        var selectedProvider: Episode.Provider.ID?
        var selectedSource: Source.ID?
        var selectedSidebar: Sidebar?

        // Internal

        var isOffline = false
        var hasInitialized = false

        // Player State

        var player = AVPlayerCore.State()

        init(
            anime: Anime,
            episodes: IdentifiedArrayOf<Episode>?,
            selectedEpisode: Episode.ID
        ) {
            self.anime = anime
            self.episodes = episodes != nil ? .success(episodes!) : .idle
            self.selectedEpisode = selectedEpisode
        }
    }

    enum Action: Equatable {

        // View Actions

        case onAppear
        case backwardsTapped
        case forwardTapped
        case playerTapped
        case close

        // Internal Actions

        case initializeFirstTime

        // Fetching

        case fetchEpisodes
        case fetchedEpisodes(Result<[Episode], EquatableError>)
        case fetchSources
        case fetchedSources(Result<[Source], EquatableError>)

        // Player Actions

        case player(AVPlayerCore.Action)
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
        } else if (episode?.providers.count ?? 0) > 0 && !sources.finished {
            return .fetchingSources
        }
        return nil
    }
}

// MARK: Error State

extension VideoPlayerV2Core.State {
    enum Error {
        case failedToLoadEpisodes
        case failedToFindProviders
        case failedToLoadSources
    }

    var error: Error? {
        if case .failed = episodes {
            return .failedToLoadEpisodes
        } else if case .success(let episodes) = episodes, episodes.count == 0 {
            return .failedToLoadEpisodes
        } else if episode?.providers.count == nil || episode!.providers.count == 0 {
            return .failedToFindProviders
        } else if case .failed = sources {
            return .failedToLoadSources
        }
        return nil
    }
}

extension VideoPlayerV2Core.State {
    fileprivate var episode: Episode? {
        if let episodes = episodes.value {
            return episodes[id: selectedEpisode]
        }

        return nil
    }

    fileprivate var provider: Episode.Provider? {
        if let episode = episode, let selectedProvider = selectedProvider {
            return episode.providers.first(where: { $0.id == selectedProvider })
        }

        return nil
    }

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
                guard !state.hasInitialized else { break }
                return .init(value: .initializeFirstTime)
            case .backwardsTapped:
                break
            case .forwardTapped:
                break
            case .playerTapped:
                break

            // Internal Actions

            case .initializeFirstTime:
                return .concatenate(
                    .init(value: .player(.avAction(.initialize))),
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
                guard let provider = state.provider ?? state.episode?.providers.first else { break }

                state.sources = .loading
                return environment.animeClient.getSources(provider)
                    .receive(on: environment.mainQueue)
                    .catchToEffect()
                    .map(Action.fetchedSources)

            case .fetchedSources(.success(let sources)):
                state.sources = .success(.init(uniqueElements: sources.sorted(by: \.quality)))
                state.selectedSource = sources.first?.id

            case .fetchedSources(.failure):
                state.sources = .failed
                state.selectedSource = nil

            case .player:
                break
            case .close:
                break
            }

            return .none
        }
        .debugActions()
    }
}
