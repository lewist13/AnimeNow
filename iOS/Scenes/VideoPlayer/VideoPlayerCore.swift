//
//  PlayerCore.swift
//  Anime Now!
//
//  Created Erik Bautista on 9/14/22.
//  Copyright © 2022. All rights reserved.
//

import ComposableArchitecture
import Foundation
import AVFoundation
import SwiftUI

enum VideoPlayerCore {
    struct State: Equatable {
        let sources: [EpisodeSource]

        var showingOverlay = true
        var showingSettings = false

        // Player State
        var avPlayerState = AVPlayerCore.State()
    }

    enum Action: Equatable {
        case onAppear
        case startPlayer
        case tappedPlayer
        case showOverlay(Bool)
        case hideOverlayAnimationDelay
        case cancelHideOverlayAnimationDelay
        case closeButtonPressed
        case close

        // Player Action Controls
        case togglePlayback
        case startSeeking
        case slidingSeeker(Double)
        case doneSeeking
        case player(AVPlayerCore.Action)
    }

    struct Environment {
        let mainQueue: AnySchedulerOf<RunLoop>
        let mainRunLoop: AnySchedulerOf<RunLoop>
        let userDefaultsClient: UserDefaultsClient
    }
}

extension VideoPlayerCore {
    static let reducer = Reducer<Self.State, Self.Action, Self.Environment>.combine(
        .init { state, action, environment in
            struct HideOverlayAnimationTimeout: Hashable {}
            let overlayVisibilityAnimation = Animation.easeInOut(duration: 0.5)

            switch action {
            case .onAppear:
                return .merge(
                    .init(value: .startPlayer)
                )
            case .tappedPlayer:
                let showingOverlay = !state.showingOverlay

                var effects: [Effect<Self.Action, Never>] = [
                    .init(value: .showOverlay(showingOverlay))
                        .receive(on: environment.mainQueue.animation(overlayVisibilityAnimation))
                        .eraseToEffect()
                ]

                if showingOverlay && state.avPlayerState.timeStatus == .playing {
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
            case .showOverlay(let showing):
                state.showingOverlay = showing
            case .hideOverlayAnimationDelay:
                return .init(value: .showOverlay(false))
                    .delay(for: 5, scheduler: environment.mainQueue.animation(overlayVisibilityAnimation))
                    .eraseToEffect()
                    .cancellable(id: HideOverlayAnimationTimeout())
            case .cancelHideOverlayAnimationDelay:
                return .cancel(id: HideOverlayAnimationTimeout())
            case .closeButtonPressed:
                return .concatenate(
                    [
                        .cancel(id: HideOverlayAnimationTimeout()),
                        .init(value: .player(.avAction(.stop))),
                        .init(value: .close)
                            .delay(for: 0.25, scheduler: environment.mainQueue)
                            .eraseToEffect()
                    ]
                )
            case .close:
                break

            // MARK: AVPlayer Actions

            case .startPlayer:
                let asset = AVAsset(url: state.sources.first!.url)
                let media = AVPlayerItem(asset: asset)
                return .concatenate(
                    [
                        .init(value: .player(.avAction(.initialize)))
                            .delay(for: 1, scheduler: environment.mainQueue)
                            .eraseToEffect(),
                        .init(value: .player(.avAction(.start(media: media)))),
                        .init(value: .player(.avAction(.play)))
                    ]
                )
            case .togglePlayback:
                if state.avPlayerState.timeStatus == .playing {
                    return .init(value: .player(.avAction(.pause)))
                } else {
                    return .init(value: .player(.avAction(.play)))
                }
    
            case .startSeeking:
                return .concatenate(
                    .init(value: .player(.avAction(.pause))),
                    .init(value: .cancelHideOverlayAnimationDelay)
                )
            case .slidingSeeker(let val):
                let duration = state.avPlayerState.duration ?? .zero
                let seconds = CMTimeValue(max(0, min(val, duration.seconds)))
                let newTime = CMTime(
                    value: seconds,
                    timescale: 1
                )

                return .init(value: .player(.currentTime(newTime)))
            case .doneSeeking:
                return .concatenate(
                    .init(value: .player(.avAction(.seek(to: state.avPlayerState.currentTime)))),
                    .init(value: .player(.avAction(.play))).delay(for: 0.5, scheduler: environment.mainQueue)
                        .eraseToEffect()
                )
            case .player(.timeStatus(.playing, nil)):
                if state.showingOverlay {
                    return .init(value: .hideOverlayAnimationDelay)
                }
            case .player(.timeStatus(.paused, nil)):
                if state.showingOverlay {
                    return .init(value: .cancelHideOverlayAnimationDelay)
                }
            case .player:
                break
            }
            return .none
        },
        AVPlayerCore.reducer.pullback(
            state: \.avPlayerState,
            action: /VideoPlayerCore.Action.player,
            environment: { _ in () }
        )
        .debugActions()
    )
}
