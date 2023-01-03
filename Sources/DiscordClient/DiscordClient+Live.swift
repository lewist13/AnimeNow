//
//  File.swift
//  
//
//  Created by ErrorErrorError on 12/30/22.
//  
//

#if os(macOS)

import SwordRPC
import APIClient
import Foundation
import ComposableArchitecture

extension DiscordClient {
    public static let liveValue: Self = {
        let animeNowAPI = AnimeNowAPI.shared

        let sword = SwordRPC(
            appId: animeNowAPI.discordClientKey
        )

        return .init(
            isActive: sword.isRunning,
            isConnected: sword.isConnected
        ) { active in
            if active && !sword.isRunning {
                sword.start()
            } else if !active && sword.isRunning {
                sword.stop()
            }
        } setActivity: { activity in
            switch activity {
            case .none:
                sword.setPresence(nil)

            case .some(.watching(let info)):
                var presence = RichPresence()
                presence.state = info.name
                presence.details = info.episode
                presence.assets.largeText = info.episode
                presence.assets.largeImage = info.image
                presence.assets.smallImage = "logo"
                presence.assets.smallText = "Anime Now!"

                if info.duration > 0 {
                    let main = Date()
                    let currentProgress = info.progress * info.duration
                    presence.timestamps.start = main - currentProgress
                    presence.timestamps.end = main + info.duration - currentProgress
                }

                var button = RichPresence.Button()
                button.label = "Watch Now"
                button.url = "animenow://watch"
                presence.buttons.append(button)

                sword.setPresence(presence)

            case .some:
                break
            }
        }
    }()
}

#endif
