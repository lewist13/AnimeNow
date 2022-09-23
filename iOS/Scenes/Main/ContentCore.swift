//
//  ContentCore.swift
//  Anime Now!
//
//  Created Erik Bautista on 9/4/22.
//  Copyright © 2022. All rights reserved.
//

import SwiftUI
import Foundation
import ComposableArchitecture


enum ContentCore {
    struct State: Equatable {
        var home = HomeCore.State()
        var search = SearchCore.State()
        var settings = SettingsCore.State()

        var videoPlayer: VideoPlayerCore.State?
        var animeDetail: AnimeDetailCore.State?
    }

    enum Action: Equatable {
        case onAppear
        case setAnimeDetail(AnimeDetailCore.State?)
        case home(HomeCore.Action)
        case search(SearchCore.Action)
        case settings(SettingsCore.Action)
        case videoPlayer(VideoPlayerCore.Action)
        case animeDetail(AnimeDetailCore.Action)
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
                    mainQueue: $0.mainQueue,
                    animeClient: $0.animeClient,
                    mainRunLoop: $0.mainRunLoop,
                    userDefaultsClient: $0.userDefaultsClient
                )
            }
        ),
        AnimeDetailCore.reducer.optional().pullback(
            state: \.animeDetail,
            action: /ContentCore.Action.animeDetail,
            environment: {
                .init(
                    animeClient: $0.animeClient,
                    mainQueue: $0.mainQueue,
                    mainRunLoop: $0.mainRunLoop
                )
            }
        ),
        .init { state, action, environment in
            switch action {
            case let .animeDetail(.play(anime, episodes, selected)):
                state.videoPlayer = .init(anime: anime, episodes: episodes, selectedEpisode: selected)
                return environment.orientationClient.setOrientation(.landscapeRight)
                    .fireAndForget()
            case .videoPlayer(.close):
                state.videoPlayer = nil
                return environment.orientationClient.setOrientation(.portrait)
                    .fireAndForget()
            case .setAnimeDetail(let animeMaybe):
                state.animeDetail = animeMaybe
            case .home(.animeTapped(let anime)):
                let animation = Animation.interactiveSpring(response: 0.35, dampingFraction: 1.0)
                return .init(value: .setAnimeDetail(.init(anime: anime)))
                    .receive(
                        on: environment.mainQueue.animation(animation)
                    )
                    .eraseToEffect()
            case .animeDetail(.close):
                return .init(value: .setAnimeDetail(nil))
                    .receive(
                        on: environment.mainQueue.animation(.easeInOut(duration: 0.25))
                    )
                    .eraseToEffect()
            default:
                break
            }
            return .none
        }
    )
}
