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

enum VideoPlayerCore {
    enum PlayerStatus: String {
        case playing, paused, stopped
    }

    struct State: Equatable {
        let sources: [EpisodeSource]

        var showingOverlay = true

        // Player State
        var avPlayerState = AVPlayerCore.State()

        // Player Status
        var playerStatus = PlayerStatus.stopped
    }

    enum Action: Equatable {
        case startPlayer
        case togglePlayback
        case seek(to: Float)
        case closeButtonPressed
        case close
        case player(AVPlayerCore.Action)
    }

    struct Environment {
        let mainQueue: AnySchedulerOf<RunLoop>
    }
}

extension VideoPlayerCore {
    static let reducer = Reducer<Self.State, Self.Action, Self.Environment>.combine(
        .init { state, action, environment in
            switch action {
            case .startPlayer:
                if state.playerStatus != .stopped {
                    break
                }
                return .concatenate(
                    [
                        .init(value: .player(.avAction(.begin))).delay(for: 1, scheduler: DispatchQueue.main).eraseToEffect(),
                        .init(value: .player(.avAction(.start(media: .init(url: state.sources.first!.url)))))
                    ]
                )
            case .togglePlayback:
                if state.playerStatus == .paused {
                    return .init(value: .player(.avAction(.play)))
                } else if state.playerStatus == .playing {
                    state.avPlayerState.avAction = .pause
                    return .init(value: .player(.avAction(.pause)))
                }

            case .seek(to: let val):
                break
            case .closeButtonPressed:
                state.playerStatus = .stopped
                return .concatenate(
                    [
                        .init(value: .player(.avAction(.stop))),
                        .init(value: .close)
                    ]
                )
            case .close:
                break
            case .player(.rate(let rate)):
                if rate > 0 {
                    state.playerStatus = .playing
                } else {
                    state.playerStatus = .paused
                }
            case .player(.status(.readyToPlay)):
                return .init(value: .player(.avAction(.seek(to: .init(value: 5, timescale: 1)))))
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
    )
}
