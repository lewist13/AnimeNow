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
        let mainQueue: AnySchedulerOf<DispatchQueue>
        let mainRunLoop: AnySchedulerOf<RunLoop>
        let orientationClient: OrientationClient
        let userDefaultsClient: UserDefaultsClient
    }
}

extension ContentCore.Environment {
    static let live = Self(
        animeClient: .live(),
        mainQueue: .main.eraseToAnyScheduler(),
        mainRunLoop: .main.eraseToAnyScheduler(),
        orientationClient: .live,
        userDefaultsClient: .live
    )

    static let mock = Self.init(
        animeClient: .mock,
        mainQueue: .main.eraseToAnyScheduler(),
        mainRunLoop: .main.eraseToAnyScheduler(),
        orientationClient: .mock,
        userDefaultsClient: .mock
    )
}

extension ContentCore {
    static var reducer = Reducer<ContentCore.State, ContentCore.Action, ContentCore.Environment>.combine(
        HomeCore.reducer.pullback(
            state: \.home,
            action: /ContentCore.Action.home,
            environment: {
                .init(
                    animeClient: $0.animeClient,
                    mainQueue: $0.mainQueue,
                    mainRunLoop: $0.mainRunLoop
                )
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
            environment: {
                .init(
                    mainQueue: $0.mainRunLoop,
                    mainRunLoop: $0.mainRunLoop,
                    userDefaultsClient: $0.userDefaultsClient
                )
            }
        ),
        .init { state, action, environment in
            switch action {
            case .home(.animeDetail(.fetchedSources(.success(let episodeSources)))):
                state.videoPlayer = .init(sources: episodeSources)
                return environment.orientationClient.setOrientation(.landscapeRight)
                    .fireAndForget()
            case .videoPlayer(.close):
                state.videoPlayer = nil
                return environment.orientationClient.setOrientation(.portrait)
                    .fireAndForget()
            default:
                break
            }
            return .none
        }
    )
}
