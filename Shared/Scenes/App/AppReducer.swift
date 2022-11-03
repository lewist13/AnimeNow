//
//  AppReducer.swift
//  Anime Now!
//
//  Created by ErrorErrorError on 9/4/22.
//  Copyright © 2022. All rights reserved.
//

import SwiftUI
import ComposableArchitecture

struct AppReducer: ReducerProtocol {
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

        static var allCases: [AppReducer.Route] {
            return [.home, .search, .collection]
        }
    }

    struct State: Equatable {
        @BindableState var route = Route.home

        var appDelegate = AppDelegateReducer.State()

        var home = HomeReducer.State()
        var collection = CollectionsReducer.State()
        var search = SearchReducer.State()
        var settings = SettingsReducer.State()
        var downloads = DownloadsReducer.State()

        var videoPlayer: AnimePlayerReducer.State?
        var animeDetail: AnimeDetailReducer.State?
    }

    enum Action: BindableAction {
        case onAppear
        case setVideoPlayer(AnimePlayerReducer.State?)
        case setAnimeDetail(AnimeDetailReducer.State?)
        case appDelegate(AppDelegateReducer.Action)
        case home(HomeReducer.Action)
        case collection(CollectionsReducer.Action)
        case search(SearchReducer.Action)
        case downloads(DownloadsReducer.Action)
        case settings(SettingsReducer.Action)
        case videoPlayer(AnimePlayerReducer.Action)
        case animeDetail(AnimeDetailReducer.Action)
        case binding(BindingAction<State>)
    }

    @Dependency(\.mainQueue) var mainQueue
}

extension AppReducer.State {
    var hasPendingChanges: Bool {
        videoPlayer != nil
    }
}

extension AppReducer {
    @ReducerBuilder<State, Action>
    var body: Reduce<State, Action> {
        Scope(state: \.appDelegate, action: /Action.appDelegate) {
            AppDelegateReducer()
        }

        Scope(state: \.home, action: /Action.home) {
            HomeReducer()
        }

        Scope(state: \.search, action: /Action.search) {
            SearchReducer()
        }

        Scope(state: \.downloads, action: /Action.downloads) {
            DownloadsReducer()
        }

        Scope(state: \.settings, action: /Action.settings) {
            SettingsReducer()
        }

        BindingReducer()

        Reduce(self.core)
            .ifLet(\.videoPlayer, action: /Action.videoPlayer) {
                AnimePlayerReducer()
            }
            .ifLet(\.animeDetail, action: /Action.animeDetail) {
                AnimeDetailReducer()
            }
    }

    func core(state: inout State, action: Action) -> EffectTask<Action> {
        switch action {

        case .setVideoPlayer(let item):
            state.videoPlayer = item

        case .setAnimeDetail(let animeMaybe):
            if let anime = animeMaybe, state.animeDetail == nil {
                // Allow only replacing anime detail one at a time
                state.animeDetail = anime
            } else if animeMaybe == nil {
                state.animeDetail = nil
            }

        case let .home(.animeTapped(anime)),
             let .search(.onAnimeTapped(anime)):
            return .action(
                .setAnimeDetail(.init(anime: anime)),
                animation: .interactiveSpring(response: 0.35, dampingFraction: 1.0)
            )

        case let .home(.resumeWatchingTapped(resumeWatching)):
            return .action(
                .setVideoPlayer(
                    .init(
                        anime: resumeWatching.animeStore.asRepresentable(),
                        selectedEpisode: Episode.ID(resumeWatching.episodeStore.number)
                    )
                )
            )

        case let .animeDetail(.play(anime, episodes, selected)):
            return .action(
                .setVideoPlayer(
                    .init(
                        anime: anime.asRepresentable(),
                        episodes: episodes.map({ $0.asRepresentable() }),
                        selectedEpisode: selected
                    )
                )
            )

        case .animeDetail(.close):
            return .action(
                .setAnimeDetail(nil),
                animation: .easeInOut(duration: 0.25)
            )

        case .videoPlayer(.close):
            return .action(
                .setVideoPlayer(nil)
            )
        case .appDelegate(.appDidEnterBackground):
            let videoStoreUp = state.videoPlayer != nil
            return .run { send in
                if videoStoreUp {
                    await send(.videoPlayer(.storeState))
                }
            }

        case .appDelegate(.appWillTerminate):
            return .run { send in
                await send(.appDelegate(.appDidEnterBackground))
                #if os(macOS)
                // for macOS, save everything before fully closing app.
                try? await mainQueue.sleep(for: 0.5)
                await NSApp.reply(toApplicationShouldTerminate: true)
                #endif
            }

        default:
            break
        }
        return .none
    }
}
