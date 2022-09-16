//
//  ContentCore.swift
//  Anime Now!
//
//  Created Erik Bautista on 9/4/22.
//  Copyright © 2022. All rights reserved.
//

import Foundation
import ComposableArchitecture

enum ContentCore {
    struct State: Equatable {
        var home = HomeCore.State()
        var search = SearchCore.State()
        var settings = SettingsCore.State()
        var videoPlayer: VideoPlayerCore.State?
    }

    enum Action: Equatable {
        case onAppear
        case home(HomeCore.Action)
        case search(SearchCore.Action)
        case settings(SettingsCore.Action)
        case videoPlayer(VideoPlayerCore.Action)
    }

    struct Environment {
        let animeClient: AnimeClient
        let mainRunLoop: AnySchedulerOf<RunLoop>
        let videoPlayerClient: VideoPlayerClient
        let userDefaultsClient: UserDefaultsClient
    }
}

extension ContentCore {
    static var reducer = Reducer<ContentCore.State, ContentCore.Action, ContentCore.Environment>.combine(
        HomeCore.reducer.pullback(
            state: \.home,
            action: /ContentCore.Action.home,
            environment: { .init(animeClient: $0.animeClient)
            }
        ),
        SearchCore.reducer.pullback(
            state: \.search,
            action: /ContentCore.Action.search,
            environment: { .init(animeClient: $0.animeClient)
            }
        ),
        SettingsCore.reducer.pullback(
            state: \.settings,
            action: /ContentCore.Action.settings,
            environment: { _ in .init() }
        ),
        VideoPlayerCore.reducer.optional().pullback(
            state: \.videoPlayer,
            action: /ContentCore.Action.videoPlayer,
            environment: { .init(mainQueue: $0.mainRunLoop) }
        ),
        .init { state, action, environment in
            return .none
        }
    )
}
