//
//  VideoPlayerCore.swift
//  Anime Now!
//
//  Created Erik Bautista on 10/1/22.
//  Copyright © 2022. All rights reserved.
//

import Foundation
import ComposableArchitecture
import AVFoundation
import SwiftUI

enum VideoPlayerCore {
    enum Sidebar: CustomStringConvertible {
        case episodes
        case providers
        case sources
        case subtitles

        var description: String {
            switch self {
            case .episodes:
                return "Episodes"
            case .providers:
                return "Providers"
            case .sources:
                return "Sources"
            case .subtitles:
                return "Subtitles"
            }
        }
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
        case showEpisodesSidebar
        case closeButtonTapped
        case closeSidebar

        case selectEpisode(Episode.ID)
        case selectProvider(Episode.Provider.ID?)
        case selectSource(Source.ID?)

        // Internal Actions

        case initializeFirstTime
        case saveEpisodeProgress(Episode.ID?)
        case setSidebar(Sidebar?)
        case showPlayerOverlay(Bool)
        case hideOverlayAnimationDelay
        case cancelHideOverlayAnimationDelay
        case close

        case fetchedAnimeInfoStore([AnimeInfoStore])
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

// MARK: Status State

extension VideoPlayerCore.State {
    enum Status: Equatable {
        case loading
        case playing
        case paused
        case replay
        case error(String)
    }

    // TODO: Merge error state with status

    var status: Status? {

        // Error States

        if case .failed = episodes {
            return .error("There was an error retrieving episodes at this time. Please try again later.")
        } else if case .success(let episodes) = episodes, episodes.count == 0 {
            return .error("There was an error retrieving episodes at this time. Please try again later.")
        } else if let episode = episode, episode.providers.count == 0 {
            return .error("There are no providers available for this episode. Please try again later.")
        } else if case .failed = sources {
            return .error("There was an error trying to retrieve sources. Please try again later.")
        } else if case .success(let sources) = sources, sources.count == 0 {
            return .error("There are currently no sources available for this episode. Please try again later.")
        } else if player.status == .failed {
            return .error("There was an error starting video player. Please try again later.")

        // Loading States

        } else if !episodes.finished {
            return .loading
        } else if (episode?.providers.count ?? 0) > 0 && !sources.finished {
            return .loading
        } else if player.playerItemStatus == .unknown {
            return .loading
        } else if player.playerItemStatus == .readyToPlay {
            if player.timeStatus == .waitingToPlayAtSpecifiedRate {
                return .loading
            } else if player.timeStatus == .playing {
                return .playing
            } else {
                return .paused
            }
        }
        return nil
    }
}

// MARK: Progress and Duration State

extension VideoPlayerCore.State {
    var progress: Double {
        guard let duration = duration, duration > 0 else { return 0 }
        return player.currentTime.seconds / duration
    }

    var duration: Double? {
        return player.duration?.seconds
    }
}

// MARK: Episode Properties

extension VideoPlayerCore.State {
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

extension VideoPlayerCore {
    static var reducer: Reducer<VideoPlayerCore.State, VideoPlayerCore.Action, VideoPlayerCore.Environment> = .combine(
        AVPlayerCore.reducer.pullback(
            state: \.player,
            action: /Action.player,
            environment: { _ in () }
        ),
        .init { state, action, environment in
            struct HidePlayerOverlayDelayCancellable: Hashable {}
            struct FetchEpisodesCancellable: Hashable {}
            struct FetchSourcesCancellable: Hashable {}
            struct AnimeInfoStoreObservableCancellable: Hashable {}

            let overlayVisibilityAnimation = Animation.easeInOut(
                duration: 0.5
            )

            switch action {

            // View Actions

            case .onAppear:
                guard !state.hasInitialized else { break }
                return .merge(
                    .init(value: .initializeFirstTime),
                    environment.repositoryClient.observe(
                        .init(
                            format: "id == %d",
                            state.anime.id
                        ),
                        []
                    )
                    .receive(on: environment.mainQueue)
                    .eraseToEffect()
                    .map(Action.fetchedAnimeInfoStore)
                    .cancellable(id: AnimeInfoStoreObservableCancellable())
                )

            case .playerTapped:
                guard state.selectedSidebar == nil else {
                    return .init(value: .closeSidebar)
                }

                let showingOverlay = !state.showPlayerOverlay

                var effects: [Effect<Action, Never>] = [
                    .init(value: .showPlayerOverlay(showingOverlay))
                        .receive(on: environment.mainQueue.animation(overlayVisibilityAnimation))
                        .eraseToEffect()
                ]

                if showingOverlay && state.player.timeStatus == .playing {
                    // Show overlay with timeout if the video is currently playing
                    effects.append(
                        .init(value: .hideOverlayAnimationDelay)
                    )
                } else {
                    effects.append(
                        .init(value: .cancelHideOverlayAnimationDelay)
                    )
                }

                return .concatenate(effects)

            case .showEpisodesSidebar:
                return .init(value: .setSidebar(.episodes))
                    .receive(on: environment.mainQueue.animation(.easeInOut(duration: 0.25)))
                    .eraseToEffect()

            case .closeButtonTapped:
                return .concatenate(
                    .cancel(id: FetchSourcesCancellable()),
                    .cancel(id: FetchEpisodesCancellable()),
                    .init(value: .saveEpisodeProgress(state.episode?.id)),
                    .init(value: .player(.avAction(.terminate))),
                    .init(value: .close)
                        .delay(for: 0.25, scheduler: environment.mainQueue)
                        .eraseToEffect()
                )

            case .closeSidebar:
                return .init(value: .setSidebar(nil))
                    .receive(on: environment.mainQueue.animation(.easeInOut(duration: 0.25)))
                    .eraseToEffect()

            case .selectEpisode(let episodeId):
                var effects = [Effect<Action, Never>]()

                effects.append(.init(value: .saveEpisodeProgress(state.episode?.id)))

                state.selectedEpisode = episodeId
                // TODO: Add user defaults for preferred provider or fallback to first
                let provider = state.episode?.providers.first?.id

                effects.append(.init(value: .player(.avAction(.stop))))
                effects.append(.init(value: .selectProvider(provider)))

                return .merge(effects)

            case .selectProvider(let providerId):
                state.selectedProvider = providerId
                return .init(value: .fetchSources)

            case .selectSource(let sourceId):
                state.selectedSource = sourceId

                guard let source = state.source else { break }

                let asset = AVAsset(url: source.url)
                let item = AVPlayerItem(asset: asset)

                return .init(value: .player(.avAction(.start(media: item))))
                    .receive(on: environment.mainQueue)
                    .eraseToEffect()

            // Internal Actions

            case .initializeFirstTime:
                state.hasInitialized = true
                return .concatenate(
                    .init(value: .player(.avAction(.initialize))),
                    .init(value: .fetchEpisodes)
                )

            case .showPlayerOverlay(let show):
                state.showPlayerOverlay = show

            case .hideOverlayAnimationDelay:
                return .init(value: .showPlayerOverlay(false))
                    .delay(
                        for: 5,
                        scheduler:  environment.mainQueue
                            .animation(overlayVisibilityAnimation)
                    )
                    .eraseToEffect()
                    .cancellable(id: HidePlayerOverlayDelayCancellable())

            case .cancelHideOverlayAnimationDelay:
                return .cancel(id: HidePlayerOverlayDelayCancellable())

            case .saveEpisodeProgress(let episodeId):
                guard let episodeId = episodeId, let episode = state.episodes.value?[id: episodeId] else { break }
                guard state.duration != nil else { break }
                guard var animeInfoStore = state.savedAnimeInfo.value else { break }

                let progress = state.progress

                animeInfoStore.updateProgress(for: episode, anime: state.anime, progress: progress)

                return environment.repositoryClient.insertOrUpdate(animeInfoStore)
                    .receive(on: environment.mainQueue)
                    .fireAndForget()

            case .close:
                break

            case .setSidebar(let route):
                state.selectedSidebar = route

                if route != nil {
                    return .merge(
                        .init(value: .cancelHideOverlayAnimationDelay),
                        .init(value: .showPlayerOverlay(false))
                    )
                }

            // Fetch Anime Info Store

            case .fetchedAnimeInfoStore(let animeInfos):
                if let animeInfo = animeInfos.first {
                    state.savedAnimeInfo = .success(animeInfo)
                } else {
                    state.savedAnimeInfo = .success(
                        .init(
                            id: state.anime.id,
                            isFavorite: false,
                            episodesInfo: .init()
                        )
                    )
                }

            // Fetch Episodes

            case .fetchEpisodes:
                guard !state.episodes.hasInitialized else {
                    if state.episode != nil {
                        return .init(value: .selectEpisode(state.selectedEpisode))
                    }
                    break
                }
                state.episodes = .loading
                return environment.animeClient.getEpisodes(state.anime.id)
                    .receive(on: environment.mainQueue)
                    .catchToEffect()
                    .map(Action.fetchedEpisodes)
                    .cancellable(id: FetchEpisodesCancellable())

            case .fetchedEpisodes(.success(let episodes)):
                state.episodes = .success(.init(uniqueElements: episodes))
                return .init(value: .selectEpisode(state.selectedEpisode))

            case .fetchedEpisodes(.failure):
                state.episodes = .failed

            // Fetch Sources

            case .fetchSources:
                guard let provider = state.provider else { break }

                state.sources = .loading
                return environment.animeClient.getSources(provider)
                    .receive(on: environment.mainQueue)
                    .catchToEffect()
                    .map(Action.fetchedSources)
                    .cancellable(id: FetchSourcesCancellable())

            case .fetchedSources(.success(let sources)):
                let sources = sources.sorted(by: \.quality).reversed()
                state.sources = .success(.init(uniqueElements: sources))
                // TODO: Set quality based on user defaults or the first one based on the one received
                return .init(value: .selectSource(sources.first?.id))

            case .fetchedSources(.failure):
                state.sources = .failed
                state.selectedSource = nil

            // Video Player Actions

            case .backwardsTapped:
                break

            case .forwardTapped:
                break

            // Internal Video Player Logic

            case .replayTapped:
                return .init(value: .player(.avAction(.replay)))

            case .togglePlayback:
                if state.status == .playing {
                    return .init(value: .player(.avAction(.pause)))
                } else {
                    return .init(value: .player(.avAction(.play)))
                }

            case .startSeeking:
                return .merge(
                    .init(value: .player(.avAction(.pause))),
                    .init(value: .cancelHideOverlayAnimationDelay)
                )

            case .stopSeeking:
                return .concatenate(
                    .init(
                        value: .player(.avAction(.seek(to: state.player.currentTime)))
                    ),
                    .init(
                        value: .player(.avAction(.play))
                    )
                    .delay(for: 0.5, scheduler: environment.mainQueue)
                    .eraseToEffect()
                )

            case .seeking(to: let to):
                guard let duration = state.duration else { break }
                let seconds = to * duration
                let item = CMTime(
                    seconds: seconds,
                    preferredTimescale: 1
                )
                return .init(value: .player(.currentTime(item)))

            case .player(.playerItemStatus(.readyToPlay)):
                return .init(value: .player(.avAction(.play)))

            case .player(.timeStatus(.playing, nil)):
                if state.showPlayerOverlay {
                    return .init(value: .hideOverlayAnimationDelay)
                }

            case .player(.timeStatus(.paused, nil)):
                if state.showPlayerOverlay {
                    return .init(value: .cancelHideOverlayAnimationDelay)
                }

            case .player:
                break
            }

            return .none
        }
            .debugActions()
    )
}
