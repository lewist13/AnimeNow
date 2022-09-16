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
    enum PlayerStatus {
        case playing, paused, stopped
    }

    struct State: Equatable {
        let source: Source

        var showingOverlay = true

        // Player State
        var avPlayerState = AVPlayerCore.State()

        // Player Status
        var playerStatus = PlayerStatus.stopped
    }

    enum Action: Equatable {
        case begin
        case togglePlayback
        case close
        case player(AVPlayerCore.Action)
    }

    struct Environment {
        let mainQueue: AnySchedulerOf<RunLoop>
    }
}

extension VideoPlayerCore {
    static let reducer = Reducer<Self.State, Self.Action, Self.Environment>.combine(
        AVPlayerCore.reducer.pullback(
            state: \.avPlayerState,
            action: /VideoPlayerCore.Action.player,
            environment: { _ in () }
        ),
        .init { state, action, environment in
            switch action {
            case .begin:
                return .merge(
                    [
                        .init(value: .player(.avAction(.begin))),
                        .init(value: .player(.avAction(.setPrimaryItem(.init(url: state.source.url))))),
                        .init(value: .player(.avAction(.play)))
                    ]
                )
            case .togglePlayback:
                if state.playerStatus == .paused {
                    return .init(value: .player(.avAction(.play)))
                } else if state.playerStatus == .playing {
                    state.avPlayerState.avAction = .pause
                    return .init(value: .player(.avAction(.pause)))
                }
            case .close:
                state.playerStatus = .stopped
                return .init(value: .player(.avAction(.stop)))
            case .player(.rate(let rate)):
                if rate > 0 {
                    state.playerStatus = .playing
                } else {
                    state.playerStatus = .paused
                }
            case .player(_):
                break
            }
            return .none
        }
    ).debug()
}
