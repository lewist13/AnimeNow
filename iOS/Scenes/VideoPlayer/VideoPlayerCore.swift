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
    struct State: Equatable {
        let sources: [EpisodeSource]

        var showingOverlay = true

        // Player State
        var avPlayerState = AVPlayerCore.State()
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
            case .togglePlayback:
                if state.avPlayerState.timeStatus == .paused {
                    return .init(value: .player(.avAction(.play)))
                } else if state.avPlayerState.timeStatus == .paused {
                    state.avPlayerState.avAction = .pause
                    return .init(value: .player(.avAction(.pause)))
                }
            case .seek(to: let val):
                break
            case .closeButtonPressed:
                return .concatenate(
                    [
                        .init(value: .player(.avAction(.stop))),
                        .init(value: .close)
                    ]
                )
            case .close:
                break

            // MARK: Player setup configuration

            case .startPlayer:
                let asset = AVAsset(url: state.sources.first!.url)
                let media = AVPlayerItem(asset: asset)
                return .concatenate(
                    [
                        .init(value: .player(.avAction(.initialize)))
                            .delay(for: 1, scheduler: DispatchQueue.main)
                            .eraseToEffect(),
                        .init(value: .player(.avAction(.start(media: media)))),
                        .init(value: .player(.avAction(.play)))
                    ]
                )
            case .player(.status(let status)):
                print("PLAYER STATUS UPDATE: \(status)")
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
