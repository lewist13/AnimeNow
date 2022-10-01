//
//  PlayerCore.swift
//  Anime Now!
//
//  Created Erik Bautista on 9/14/22.
//  Copyright © 2022. All rights reserved.
//

import SwiftUI
import ComposableArchitecture
import Foundation
import AVFoundation

enum SidebarRoute: Equatable {
    case sources
    case episodes

    var stringVal: String {
        switch self {
        case .sources:
            return "Sources"
        case .episodes:
            return "Episodes"
        }
    }
}

enum VideoPlayerCore {
    struct State: Equatable {
        let anime: Anime

        var episodesState: SidebarEpisodesCore.State
        var sourcesState: SidebarSourcesCore.State
        var sidebarRoute: SidebarRoute?

        var animeDB = LoadableState<AnimeDBModel>.idle

        // Overlays
        var showPlayerOverlay = true

        // Player State
        var playerState = AVPlayerCore.State()

        var initialized = false

        init(anime: Anime, episodes: IdentifiedArrayOf<Episode>, selectedEpisode: Episode.ID) {
            self.anime = anime
            self.episodesState = .init(episodes: episodes, selectedId: selectedEpisode)
            self.sourcesState = .init()
        }
    }

    enum Action: Equatable {
        case onAppear
        case tappedEpisodesSidebar
        case tappedSourcesSidebar
        case closeSidebar
        case closeSidebarAndShowOverlay
        case notifyCloseButtonTapped
        case close

        case playSource
        case fetchSourcesForSelectedEpisode

        case saveCurrentEpisodeProgress

        case setSidebar(route: SidebarRoute?)

        case fetchedAnimeDB([AnimeDBModel])

        // Sidebar Actions

        case episodes(SidebarEpisodesCore.Action)
        case sources(SidebarSourcesCore.Action)

        // Player Action Controls

        case initializePlayer
        case showPlayerControlsOverlay(Bool)
        case tappedPlayerBounds
        case togglePlayback
        case startSeeking
        case slidingSeeker(Double)
        case doneSeeking
        case hideOverlayAnimationDelay
        case cancelHideOverlayAnimationDelay
        case player(AVPlayerCore.Action)
    }

    struct Environment {
        let mainQueue: AnySchedulerOf<DispatchQueue>
        let animeClient: AnimeClient
        let mainRunLoop: AnySchedulerOf<RunLoop>
        let repositoryClient: RepositoryClient
        let userDefaultsClient: UserDefaultsClient
    }
}

extension VideoPlayerCore.State {
    var showSidebarPanel: Bool {
        sidebarRoute != nil
    }
}

extension VideoPlayerCore {
    static let reducer = Reducer<Self.State, Self.Action, Self.Environment>.combine(
        .init { state, action, environment in
            struct HideOverlayAnimationTimeout: Hashable {}
            struct CancelEpisodeSourceFetchingId: Hashable {}
            struct ObservingAnimeInfoId: Hashable {}

            let overlayVisibilityAnimation = Animation.easeInOut(duration: 0.5)

            switch action {
            case .onAppear:
                if state.initialized {
                    break
                }
                return .merge(
                    .init(value: .initializePlayer)
                        .concatenate(with: .init(value: .fetchSourcesForSelectedEpisode)),
                    environment.repositoryClient.observe(.init(format: "id == %d", state.anime.id), [])
                        .receive(on: environment.mainQueue)
                        .eraseToEffect()
                        .map(Action.fetchedAnimeDB)
                        .cancellable(id: ObservingAnimeInfoId())
                )

            case .episodes(.aboutToChangeEpisode):
                return .init(value: .saveCurrentEpisodeProgress)
            case .episodes(.selected):
                return .merge(
                    .init(value: .closeSidebarAndShowOverlay),
                    .init(value: .player(.avAction(.stop))),
                    .init(value: .fetchSourcesForSelectedEpisode)
               )

            case .sources(.selected):
                return .init(value: .playSource)

            case .fetchSourcesForSelectedEpisode:
                if let selectedEpisode = state.episodesState.episode {
                    return .init(value: .sources(.fetchSources(episodeId: selectedEpisode.id)))
                        .cancellable(id: CancelEpisodeSourceFetchingId())
                }
            case .sources(.fetchedSources(.success)):
                return .init(value: .playSource)
            case .playSource:
                guard let source = state.sourcesState.source else {
                    break
                }

                let asset = AVAsset(url: source.url)
                let item = AVPlayerItem(asset: asset)

                return .concatenate(
                    .init(value: .player(.avAction(.start(media: item))))
                        .delay(for: 0.5, scheduler: environment.mainQueue)
                        .eraseToEffect(),
                    .init(value: .player(.avAction(.play)))
                )
            case .tappedEpisodesSidebar:
                return .init(value: .setSidebar(route: .episodes))
                    .receive(on: environment.mainQueue.animation(.easeInOut(duration: 0.25)))
                    .eraseToEffect()
            case .tappedSourcesSidebar:
                return .init(value: .setSidebar(route: .sources))
                    .receive(on: environment.mainQueue.animation(.easeInOut(duration: 0.25)))
                    .eraseToEffect()
            case .tappedPlayerBounds:
                guard state.sidebarRoute == nil else {
                    return .init(value: .closeSidebar)
                }

                let showingOverlay = !state.showPlayerOverlay

                var effects: [Effect<Self.Action, Never>] = [
                    .init(value: .showPlayerControlsOverlay(showingOverlay))
                        .receive(on: environment.mainQueue.animation(overlayVisibilityAnimation))
                        .eraseToEffect()
                ]

                if showingOverlay && state.playerState.timeStatus == .playing {
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
            case .showPlayerControlsOverlay(let showing):
                state.showPlayerOverlay = showing
            case .hideOverlayAnimationDelay:
                return .init(value: .showPlayerControlsOverlay(false))
                    .delay(for: 5, scheduler: environment.mainQueue.animation(overlayVisibilityAnimation))
                    .eraseToEffect()
                    .cancellable(id: HideOverlayAnimationTimeout())
            case .cancelHideOverlayAnimationDelay:
                return .cancel(id: HideOverlayAnimationTimeout())
            case .closeSidebarAndShowOverlay:
                state.sidebarRoute = nil
                return .init(value: .tappedPlayerBounds)
            case .closeSidebar:
                return .init(value: .setSidebar(route: nil))
                    .receive(on: environment.mainQueue.animation(.easeInOut(duration: 0.25)))
                    .eraseToEffect()
            case .notifyCloseButtonTapped:
                return .concatenate(
                    [
                        .cancel(id: CancelEpisodeSourceFetchingId()),
                        .cancel(id: ObservingAnimeInfoId()),
                        .cancel(id: HideOverlayAnimationTimeout()),
                        .init(value: .saveCurrentEpisodeProgress),
                        .init(value: .player(.avAction(.terminate))),
                        .init(value: .close)
                            .delay(for: 0.25, scheduler: environment.mainQueue)
                            .eraseToEffect()
                    ]
                )
            case .close:
                break
            case .setSidebar(route: let route):
                state.sidebarRoute = route
                if route != nil {
                    return .init(value: .showPlayerControlsOverlay(false))
                }

            case .saveCurrentEpisodeProgress:
                if var animeDB = state.animeDB.value,
                    let episode = state.episodesState.episode,
                    let duration = state.playerState.duration {

                    let progress = state.playerState.currentTime.seconds / duration.seconds

                    let progressInfo: ProgressInfo

                    if var episodeProgress = animeDB.progressInfos.first(where: { $0.number == episode.number }) {
                        episodeProgress.progress = progress
                        episodeProgress.lastUpdated = .init()
                        progressInfo = episodeProgress
                    } else {
                        progressInfo = .init(
                            number: Int16(episode.number),
                            progress: progress,
                            lastUpdated: .init()
                        )
                    }

                    animeDB.progressInfos.insertOrUpdate(progressInfo)

                    return environment.repositoryClient.insertOrUpdate(animeDB)
                        .receive(on: environment.mainQueue)
                        .fireAndForget()
                }
            case .fetchedAnimeDB(let animesDB):
                if let animeDB = animesDB.first {
                    state.animeDB = .success(animeDB)
                } else {
                    state.animeDB = .success(
                        .init(
                            id: Int64(state.anime.id),
                            isFavorite: false,
                            progressInfos: .init()
                        )
                    )
                }
            case .sources(_):
                break

            // MARK: AVPlayer Actions

            case .initializePlayer:
                state.initialized = true
                return .concatenate(
                        .init(value: .player(.avAction(.initialize)))
                )
            case .togglePlayback:
                if state.playerState.timeStatus == .playing {
                    return .init(value: .player(.avAction(.pause)))
                } else {
                    return .init(value: .player(.avAction(.play)))
                }

            case .startSeeking:
                return .merge(
                    .init(value: .player(.avAction(.pause))),
                    .init(value: .cancelHideOverlayAnimationDelay)
                )
            case .slidingSeeker(let val):
                let duration = state.playerState.duration?.seconds ?? 0
                let seconds = CMTimeValue(max(0, min(val * duration, duration)))
                let newTime = CMTime(
                    value: seconds,
                    timescale: 1
                )

                return .init(value: .player(.currentTime(newTime)))
            case .doneSeeking:
                return .concatenate(
                    .init(value: .player(.avAction(.seek(to: state.playerState.currentTime)))),
                    .init(value: .player(.avAction(.play))).delay(for: 0.5, scheduler: environment.mainQueue)
                        .eraseToEffect()
                )
            case .player(.timeStatus(.playing, nil)):
                if state.showPlayerOverlay {
                    return .init(value: .hideOverlayAnimationDelay)
                }
            case .player(.timeStatus(.paused, nil)):
                if state.showPlayerOverlay {
                    return .init(value: .cancelHideOverlayAnimationDelay)
                }
            case .player(.duration(let duration)):
                // When a duration changes, typically when sources or episodes are being changed,
                // resume to the last progress
                if let duration = duration, duration != .zero {
                    let newDuration: Double

                    if let episode = state.episodesState.episode,
                       let progressInfo = state.animeDB.value?.progressInfos.first(where: { $0.id == episode.number }) {
                        newDuration = progressInfo.isFinished ? 0 : progressInfo.progress * duration.seconds
                    } else {
                        newDuration = 0.0
                    }

                    let currentTime = CMTime.init(
                        seconds: newDuration,
                        preferredTimescale: 1
                    )
                    return .init(value: .player(.avAction(.seek(to: currentTime))))
                }
            case .player:
                break
            }
            return .none
        },
        AVPlayerCore.reducer.pullback(
            state: \.playerState,
            action: /VideoPlayerCore.Action.player,
            environment: { _ in () }
        ),
        SidebarEpisodesCore.reducer.pullback(
            state: \.episodesState,
            action: /Action.episodes,
            environment: { _ in .init() }
        ),
        SidebarSourcesCore.reducer.pullback(
            state: \.sourcesState,
            action: /Action.sources,
            environment: {
                .init(
                    mainQueue: $0.mainQueue,
                    animeClient: $0.animeClient
                )
            }
        )
    )
}
