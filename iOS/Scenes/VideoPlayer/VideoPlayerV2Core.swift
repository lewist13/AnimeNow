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

        var showPlayerOverlay = true

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
        case playerTapped
        case showMoreEpisodesTapped
        case closeButtonTapped

        case selectEpisode(Episode.ID)
        case selectProvider(Episode.Provider.ID)
        case selectSource(Source.ID)
        
        // Internal Actions

        case initializeFirstTime
        case close

        // Fetching

        case fetchEpisodes
        case fetchedEpisodes(Result<[Episode], Never>)
        case fetchSources
        case fetchedSources(Result<[Source], EquatableError>)

        // Player Actions

        case backwardsTapped
        case forwardTapped
        case replayTapped
        case togglePlayback
        case startSeeking
        case stopSeeking
        case seeking(to: Double)

        // Internal Video Player Actions

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
    enum Status {
        case loading
        case playing
        case paused
        case replay
    }

    var statusState: Status? {
        if !episodes.finished {
            return .loading
        } else if !sources.finished && (episode?.providers.count ?? 0) > 0 {
            return .loading
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
        } else if let episode = episode, episode.providers.count == 0 {
            return .failedToFindProviders
        } else if case .failed = sources {
            return .failedToLoadSources
        } else if case .success(let sources) = sources, sources.count == 0 {
            return .failedToLoadSources
        }
        return nil
    }
}


// MARK: Episode Properties

extension VideoPlayerV2Core.State {
    var episode: Episode? {
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

            case .playerTapped:
                state.showPlayerOverlay.toggle()
            case .closeButtonTapped:
                return .init(value: .close)

            // Internal Actions

            case .initializeFirstTime:
                state.hasInitialized = true
                return .concatenate(
                    .init(value: .player(.avAction(.initialize))),
                    .init(value: .fetchEpisodes)
                )

            case .close:
                break

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
                state.selectedProvider = state.selectedProvider ?? state.episode?.providers.first?.id

                guard let provider = state.provider else { break }

                state.sources = .loading
                return environment.animeClient.getSources(provider)
                    .receive(on: environment.mainQueue)
                    .catchToEffect()
                    .map(Action.fetchedSources)

            case .fetchedSources(.success(let sources)):
                state.sources = .success(.init(uniqueElements: sources.sorted(by: \.quality).reversed()))
                state.selectedSource = sources.first?.id

            case .fetchedSources(.failure):
                state.sources = .failed
                state.selectedSource = nil

            // Video Player Actions

            case .backwardsTapped:
                break
            case .forwardTapped:
                break

            // Internal Video Player Logic

            case .player:
                break
                
            default:
                break
            }

            return .none
        }
        .debugActions()
    }
}
