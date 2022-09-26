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

        // Overlays
        var showPlayerOverlay = true

        // Player State
        var playerState = AVPlayerCore.State()

        init(anime: Anime, episodes: IdentifiedArrayOf<Episode>, selectedEpisode: Episode.ID) {
            self.anime = anime
            self.episodesState = .init(episodes: episodes, selectedId: selectedEpisode)
            self.sourcesState = .init()
        }
    }

    enum Action: Equatable {
        case onAppear
        case tappedPlayer
        case showPlayerControlsOverlay(Bool)
        case hideOverlayAnimationDelay
        case cancelHideOverlayAnimationDelay
        case tappedEpisodesSidebar
        case tappedSourcesSidebar
        case closeSidebar
        case closeSidebarAndShowOverlay
        case closeButtonPressed
        case close

        case setSidebar(route: SidebarRoute?)

        case playSource
        case fetchSourcesForSelectedEpisode

        // Sidebar Actions

        case episodes(SidebarEpisodesCore.Action)
        case sources(SidebarSourcesCore.Action)

        // Player Action Controls

        case initializePlayer
        case togglePlayback
        case startSeeking
        case slidingSeeker(Double)
        case doneSeeking
        case player(AVPlayerCore.Action)
    }

    struct Environment {
        let mainQueue: AnySchedulerOf<DispatchQueue>
        let animeClient: AnimeClient
        let mainRunLoop: AnySchedulerOf<RunLoop>
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

            let overlayVisibilityAnimation = Animation.easeInOut(duration: 0.5)

            switch action {
            case .onAppear:
                return .concatenate(
                    .init(value: .initializePlayer),
                    .init(value: .fetchSourcesForSelectedEpisode)
                )
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
            case .tappedPlayer:
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
                return .init(value: .tappedPlayer)
            case .closeButtonPressed:
                return .concatenate(
                    [
                        .cancel(id: HideOverlayAnimationTimeout()),
                        .cancel(id: CancelEpisodeSourceFetchingId()),
                        .init(value: .player(.avAction(.terminate))),
                        .init(value: .close)
                            .delay(for: 0.25, scheduler: environment.mainQueue)
                            .eraseToEffect()
                    ]
                )
            case .closeSidebar:
                return .init(value: .setSidebar(route: nil))
                    .receive(on: environment.mainQueue.animation(.easeInOut(duration: 0.25)))
                    .eraseToEffect()
            case .close:
                break
            case .setSidebar(route: let route):
                state.sidebarRoute = route
                if route != nil {
                    return .init(value: .showPlayerControlsOverlay(false))
                }
            case .sources(_):
                break

            // MARK: AVPlayer Actions

            case .initializePlayer:
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
                let duration = state.playerState.duration ?? .zero
                let seconds = CMTimeValue(max(0, min(val, duration.seconds)))
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
//        .debugActions(),
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
