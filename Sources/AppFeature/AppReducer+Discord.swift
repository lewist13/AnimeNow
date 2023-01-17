//
//  AppReducer+Discord.swift
//  
//
//  Created by ErrorErrorError on 1/12/23.
//  
//

import Foundation
import ComposableArchitecture

// Discord Rich Presence Reducer

extension AppReducer {
    func discordRichPresence(state: inout State, action: Action) -> EffectTask<Action> {
        switch action {
        case .setVideoPlayer(let item):
            if item == nil {
                return .run {
                    await discordClient.setActivity(nil)
                }
            }

        case .videoPlayer(.playerStatus(let status)):
            struct ThrottleStatus: Hashable { }
            if let videoState = state.videoPlayer {
                let isPlaying = status == .playback(.playing)
                return .run {
                    await discordClient.setActivity(
                        .watching(
                            .init(
                                name: videoState.anime.title,
                                episode: videoState.episode?.title ?? "Episode \(videoState.stream.selectedEpisode)",
                                image: (videoState.episode?.thumbnail?.link ?? videoState.anime.posterImage.largest?.link)?.absoluteString ?? "logo",
                                progress: isPlaying ? videoState.playerProgress : 0,
                                duration: isPlaying ? videoState.playerDuration : 0
                            )
                        )
                    )
                }
            }
        default:
            break
        }

        return .none
    }
}
