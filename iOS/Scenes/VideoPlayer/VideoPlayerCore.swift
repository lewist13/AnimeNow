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
    enum Sidebar: Equatable, CustomStringConvertible {
        case episodes
        case settings(SettingsState)
        case subtitles

        var description: String {
            switch self {
            case .episodes:
                return "Episodes"
            case .settings:
                return "Settings"
            case .subtitles:
                return "Subtitles"
            }
        }

        struct SettingsState: Equatable {
            enum Section: Equatable {
                case provider
                case quality
                case language
            }

            var selectedSection: Section?
        }
    }

    struct State: Equatable {
        let anime: Anime

        var episodes = LoadableState<IdentifiedArrayOf<Episode>>.idle
        var sources = LoadableState<IdentifiedArrayOf<Source>>.idle
        var animeStore = LoadableState<AnimeStore>.idle

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
        case showSettingsSidebar
        case closeButtonTapped
        case closeSidebar

        case selectEpisode(Episode.ID, saveProgress: Bool = true)
        case selectProvider(Episode.Provider.ID?, saveProgress: Bool = true)
        case selectSource(Source.ID?, saveProgress: Bool = true)
        case selectSidebarSettings(Sidebar.SettingsState.Section?)

        // Internal Actions

        case initializeFirstTime
        case saveEpisodeProgress(Episode.ID?)
        case setSidebar(Sidebar?)
        case showPlayerOverlay(Bool)
        case hideOverlayAnimationDelay
        case cancelHideOverlayAnimationDelay
        case close

        case fetchedAnimeInfoStore([AnimeStore])
        case fetchEpisodes
        case fetchedEpisodes(Result<[Episode], Never>)
        case fetchSources
        case fetchedSources(Result<[Source], EquatableError>)

        // Sidebar Actions

        case sidebarSettingsSection(Sidebar.SettingsState.Section?)

        // Player Actions

        case backwardsDoubleTapped
        case forwardDoubleTapped
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
        guard 0 <= player.currentTime.seconds && player.currentTime.seconds <= duration else { return 0 }
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

    var nextEpisode: Episode? {
        if let episode = episode,
           let episodes = episodes.value,
           let index = episodes.index(id: episode.id),
           (index + 1) < episodes.count {
            return episodes[index + 1]

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
                duration: 0.3
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
                        .receive(
                            on: environment.mainQueue.animation(overlayVisibilityAnimation)
                        )
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
                    .receive(on: environment.mainQueue.animation(.easeInOut(duration: 0.35)))
                    .eraseToEffect()

            case .showSettingsSidebar:
                return .init(value: .setSidebar(.settings(.init())))
                    .receive(on: environment.mainQueue.animation(.easeInOut(duration: 0.35)))
                    .eraseToEffect()

            case .closeButtonTapped:
                return .concatenate(
                    .init(value: .saveEpisodeProgress(state.episode?.id)),
                    .cancel(id: FetchSourcesCancellable()),
                    .cancel(id: FetchEpisodesCancellable()),
                    .init(value: .player(.pushAction(.terminate))),
                    .init(value: .close)
                        .delay(for: 0.25, scheduler: environment.mainQueue)
                        .eraseToEffect()
                )

            case .closeSidebar:
                return .init(value: .setSidebar(nil))
                    .receive(on: environment.mainQueue.animation(.easeInOut(duration: 0.25)))
                    .eraseToEffect()

            case .selectEpisode(let episodeId, let saveProgress):
                var effects = [Effect<Action, Never>]()

                // Before selecting episode, save progress

                if saveProgress {
                    effects.append(.init(value: .saveEpisodeProgress(state.episode?.id)))
                }

                state.selectedEpisode = episodeId

                // TODO: Add user defaults for preferred provider or fallback to first
                let provider = state.episode?.providers.first?.id

                effects.append(.init(value: .player(.pushAction(.stop))))
                effects.append(.init(value: .selectProvider(provider, saveProgress: false)))

                return .concatenate(effects)

            case .selectProvider(let providerId, let saveProgress):
                var effects = [Effect<Action, Never>]()

                // Before selecting provider, save progress

                if saveProgress {
                    effects.append(.init(value: .saveEpisodeProgress(state.episode?.id)))
                }

                state.selectedProvider = providerId

                effects.append(.init(value: .player(.pushAction(.stop))))
                effects.append(.init(value: .fetchSources))

                return .concatenate(effects)

            case .selectSource(let sourceId, let saveProgress):
                var effects = [Effect<Action, Never>]()

                // Before selecting source, save progress

                if saveProgress {
                    effects.append(.init(value: .saveEpisodeProgress(state.episode?.id)))
                }

                state.selectedSource = sourceId

                guard let source = state.source else { break }

                let asset = AVAsset(url: source.url)
                let item = AVPlayerItem(asset: asset)

                effects.append(.init(value: .player(.pushAction(.stop))))
                effects.append(
                    .init(value: .player(.pushAction(.start(media: item))))
                        .receive(on: environment.mainQueue)
                        .eraseToEffect()
                )

                return .concatenate(effects)

            case .selectSidebarSettings(let section):
                return .init(value: .sidebarSettingsSection(section))
                    .receive(on: environment.mainQueue.animation(.easeInOut(duration: 0.25)))
                    .eraseToEffect()

            // Internal Actions

            case .initializeFirstTime:
                state.hasInitialized = true
                return .merge(
                    .init(value: .player(.pushAction(.initialize))),
                    .init(value: .fetchEpisodes)
                )

            case .showPlayerOverlay(let show):
                state.showPlayerOverlay = show

            case .hideOverlayAnimationDelay:
                return .init(value: .showPlayerOverlay(false))
                    .delay(
                        for: 5,
                        scheduler:  environment.mainQueue.animation(overlayVisibilityAnimation)
                    )
                    .eraseToEffect()
                    .cancellable(id: HidePlayerOverlayDelayCancellable())

            case .cancelHideOverlayAnimationDelay:
                return .cancel(id: HidePlayerOverlayDelayCancellable())

            case .saveEpisodeProgress(let episodeId):
                guard let episodeId = episodeId, let episode = state.episodes.value?[id: episodeId] else { break }
                guard state.duration != nil else { break }
                guard var animeInfoStore = state.animeStore.value else { break }

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

            // Section actions

            case .sidebarSettingsSection(let section):
                if case .settings(var value) = state.selectedSidebar {
                    state.selectedSidebar = .settings(.init(selectedSection: section))
                }

            // Fetched Anime Store

            case .fetchedAnimeInfoStore(let animeStores):
                state.animeStore = .success(.findOrCreate(state.anime.id, animeStores))

            // Fetch Episodes

            case .fetchEpisodes:
                guard !state.episodes.hasInitialized else {
                    if state.episode != nil {
                        return .init(value: .selectEpisode(state.selectedEpisode, saveProgress: false))
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
                return .init(value: .selectEpisode(state.selectedEpisode, saveProgress: false))

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
                return .init(value: .selectSource(sources.first?.id, saveProgress: false))

            case .fetchedSources(.failure):
                state.sources = .failed
                state.selectedSource = nil

            // Video Player Actions

            case .backwardsDoubleTapped:
                let requestedTime = max(state.player.currentTime.seconds - 15, 0)

                let time = CMTime(seconds: requestedTime, preferredTimescale: 1)

                return .concatenate(
                    .init(value: .player(.currentTime(time))),
                    .init(value: .player(.pushAction(.seek(to: time))))
                )

            case .forwardDoubleTapped:
                let requestedTime = min(state.player.currentTime.seconds + 15, state.player.duration?.seconds ?? 0)

                let time = CMTime(seconds: requestedTime, preferredTimescale: 1)

                return .concatenate(
                    .init(value: .player(.currentTime(time))),
                    .init(value: .player(.pushAction(.seek(to: time))))
                )

            // Internal Video Player Logic

            case .replayTapped:
                return .init(value: .player(.pushAction(.replay)))

            case .togglePlayback:
                if state.status == .playing {
                    return .init(value: .player(.pushAction(.pause)))
                } else {
                    return .init(value: .player(.pushAction(.play)))
                }

            case .startSeeking:
                return .merge(
                    .init(value: .player(.pushAction(.pause))),
                    .init(value: .cancelHideOverlayAnimationDelay)
                )

            case .stopSeeking:
                return .concatenate(
                    .init(
                        value: .player(.pushAction(.seek(to: state.player.currentTime)))
                    ),
                    .init(
                        value: .player(.pushAction(.play))
                    )
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
                let progress: Double

                if let duration = state.duration,
                   let episode = state.episode,
                   let animeInfo = state.animeStore.value,
                   let savedEpisodeProgress = animeInfo.episodeStores.first(where: { $0.number ==  episode.number }),
                   !savedEpisodeProgress.finishedWatching {
                    progress = savedEpisodeProgress.progress * duration
                } else {
                    progress = 0.0
                }

                let item = CMTime(
                    seconds: progress,
                    preferredTimescale: 1
                )

                return .concatenate(
                    .init(
                        value: .player(.currentTime(item))
                    ),
                    .init(
                        value: .player(.pushAction(.seek(to: item)))
                    ),
                    .init(
                        value: .player(.pushAction(.play))
                    )
                )

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
            .debugActions("tca", actionFormat: .labelsOnly, environment: { _ in DebugEnvironment() })
    )
}
