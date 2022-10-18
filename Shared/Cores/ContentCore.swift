//
//  ContentCore.swift
//  Anime Now!
//
//  Created by ErrorErrorError on 9/4/22.
//  Copyright © 2022. All rights reserved.
//

import SwiftUI
import Foundation
import ComposableArchitecture

enum ContentCore {
    enum Route: String, CaseIterable {
        case home
        case search
        case collection
        case downloads

        var icon: String {
            switch self {
            case .home:
                return "house"
            case .search:
                return "magnifyingglass"
            case .downloads:
                return "arrow.down"
            case .collection:
                return "folder"
            }
        }

        var selectedIcon: String {
            switch self {
            case .home:
                return "house.fill"
            case .search:
                return self.icon
            case .downloads:
                return self.icon
            case .collection:
                return "folder.fill"
            }
        }

        var title: String {
            .init(self.rawValue.prefix(1).capitalized + self.rawValue.dropFirst())
        }

        static var allCases: [ContentCore.Route] {
            return [.home, .search]
        }
    }

    struct State: Equatable {
        @BindableState var route = Route.home

        var home = HomeCore.State()
        var collection = CollectionCore.State()
        var search = SearchCore.State()
        var settings = SettingsCore.State()
        var downloads = DownloadsCore.State()

        var videoPlayer: AnimeNowVideoPlayerCore.State?
        var animeDetail: AnimeDetailCore.State?
    }

    enum Action: BindableAction {
        case onAppear
        case setAnimeDetail(AnimeDetailCore.State?)
        case home(HomeCore.Action)
        case collection(CollectionCore.Action)
        case search(SearchCore.Action)
        case downloads(DownloadsCore.Action)
        case settings(SettingsCore.Action)
        case videoPlayer(AnimeNowVideoPlayerCore.Action)
        case animeDetail(AnimeDetailCore.Action)
        case binding(BindingAction<State>)
    }

    struct Environment {
        let animeClient: AnimeClient
        let mainQueue: AnySchedulerOf<DispatchQueue>
        let mainRunLoop: AnySchedulerOf<RunLoop>
        let repositoryClient: RepositoryClient
        let userDefaultsClient: UserDefaultsClient
    }
}

extension ContentCore.Environment {
    static let live = Self(
        animeClient: .live,
        mainQueue: .main.eraseToAnyScheduler(),
        mainRunLoop: .main.eraseToAnyScheduler(),
        repositoryClient: RepositoryClientLive.shared,
        userDefaultsClient: .live
    )

    static let mock = Self.init(
        animeClient: .mock,
        mainQueue: .main.eraseToAnyScheduler(),
        mainRunLoop: .main.eraseToAnyScheduler(),
        repositoryClient: RepositoryClientMock.shared,
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
                    mainRunLoop: $0.mainRunLoop,
                    repositoryClient: $0.repositoryClient
                )
            }
        ),
        SearchCore.reducer.pullback(
            state: \.search,
            action: /ContentCore.Action.search,
            environment: {
                .init(
                    mainQueue: $0.mainQueue,
                    animeClient: $0.animeClient
                )
            }
        ),
        DownloadsCore.reducer.pullback(
            state: \.downloads,
            action: /ContentCore.Action.downloads,
            environment: { _ in
                .init()
            }
        ),
        SettingsCore.reducer.pullback(
            state: \.settings,
            action: /ContentCore.Action.settings,
            environment: { _ in .init() }
        ),
        AnimeNowVideoPlayerCore.reducer.optional().pullback(
            state: \.videoPlayer,
            action: /ContentCore.Action.videoPlayer,
            environment: {
                .init(
                    animeClient: $0.animeClient,
                    mainQueue: $0.mainQueue,
                    mainRunLoop: $0.mainRunLoop,
                    repositoryClient: $0.repositoryClient,
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
                    mainRunLoop: $0.mainRunLoop,
                    repositoryClient: $0.repositoryClient
                )
            }
        ),
        .init { state, action, environment in
            switch action {
            case let .home(.animeTapped(anime)),
                 let .search(.onAnimeTapped(anime)):
                let animation = Animation.interactiveSpring(response: 0.35, dampingFraction: 1.0)
                return .init(value: .setAnimeDetail(.init(anime: anime)))
                    .receive(
                        on: environment.mainQueue.animation(animation)
                    )
                    .eraseToEffect()

            case let .home(.resumeWatchingTapped(episodeInfoWithAnime)):
                state.videoPlayer = .init(
                    anime: episodeInfoWithAnime.anime,
                    episodes: nil,
                    selectedEpisode: Episode.ID(episodeInfoWithAnime.episodeInfo.number)
                )

            case .setAnimeDetail(let animeMaybe):
                if let anime = animeMaybe, state.animeDetail == nil {
                    // Allow only replacing anime detail one at a time
                    state.animeDetail = anime
                } else if animeMaybe == nil {
                    state.animeDetail = nil
                }

            case let .animeDetail(.play(anime, episodes, selected)):
                state.videoPlayer = .init(anime: anime, episodes: episodes, selectedEpisode: selected)

            case .animeDetail(.close):
                return .init(value: .setAnimeDetail(nil))
                    .receive(
                        on: environment.mainQueue.animation(.easeInOut(duration: 0.25))
                    )
                    .eraseToEffect()

            case .videoPlayer(.close):
                state.videoPlayer = nil

            default:
                break
            }
            return .none
        }
            .binding()
    )
}
