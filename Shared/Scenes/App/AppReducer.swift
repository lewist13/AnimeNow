//
//  AppReducer.swift
//  Anime Now!
//
//  Created by ErrorErrorError on 9/4/22.
//  Copyright © 2022. All rights reserved.
//

import SwiftUI
import SwiftORM
import ComposableArchitecture

struct AppReducer: ReducerProtocol {
    enum Route: String, CaseIterable {
        case home
        case search
        case collection
        case downloads

        var isIconSystemImage: Bool {
            switch self {
            case .collection:
                return false
            default:
                return true
            }
        }

        var icon: String {
            switch self {
            case .home:
                return "house"
            case .search:
                return "magnifyingglass"
            case .downloads:
                return "arrow.down"
            case .collection:
                return "rectangle.stack.badge.play"
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
                return "rectangle.stack.badge.play.fill"
            }
        }

        var title: String {
            .init(self.rawValue.prefix(1).capitalized + self.rawValue.dropFirst())
        }

        static var allCases: [AppReducer.Route] {
            return [.home, .search, .collection, .downloads]
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

        var modalOverlay: ModalOverlayReducer.State?
    }

    enum Action: BindableAction {
        case onAppear
        case setVideoPlayer(AnimePlayerReducer.State?)
        case setAnimeDetail(AnimeDetailReducer.State?)
        case setModalOverlay(ModalOverlayReducer.State?)
        case onDownloadFinished(DownloaderClient.Item, URL)
        case appDelegate(AppDelegateReducer.Action)
        case home(HomeReducer.Action)
        case collection(CollectionsReducer.Action)
        case search(SearchReducer.Action)
        case downloads(DownloadsReducer.Action)
        case settings(SettingsReducer.Action)
        case videoPlayer(AnimePlayerReducer.Action)
        case animeDetail(AnimeDetailReducer.Action)
        case modalOverlay(ModalOverlayReducer.Action)
        case binding(BindingAction<State>)
    }

    @Dependency(\.repositoryClient) var repositoryClient
    @Dependency(\.downloaderClient) var downloaderClient
    @Dependency(\.mainQueue) var mainQueue

    var body: some ReducerProtocol<State, Action> {
        Scope(state: \.appDelegate, action: /Action.appDelegate) {
            AppDelegateReducer()
        }

        Scope(state: \.home, action: /Action.home) {
            HomeReducer()
        }

        Scope(state: \.search, action: /Action.search) {
            SearchReducer()
        }

        Scope(state: \.collection, action: /Action.collection) {
            CollectionsReducer()
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
            .ifLet(\.modalOverlay, action: /Action.modalOverlay) {
                ModalOverlayReducer()
            }
    }
}

extension AppReducer.State {
    var hasPendingChanges: Bool {
        videoPlayer != nil
    }
}

extension AppReducer {
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
                .setAnimeDetail(
                    .init(
                        anime: anime
                    )
                ),
                animation: .interactiveSpring(response: 0.35, dampingFraction: 1.0)
            )
        case let .collection(.onAnimeTapped(anime)):
            return .action(
                .setAnimeDetail(
                    .init(
                        anime: anime
                    )
                ),
                animation: .interactiveSpring(response: 0.35, dampingFraction: 1.0)
            )

        case let .home(.anyAnimeTapped(anime)):
            return .action(
                .setAnimeDetail(.init(anime: anime)),
                animation: .interactiveSpring(response: 0.35, dampingFraction: 1.0)
            )

        case let .home(.resumeWatchingTapped(resumeWatching)):
            return .action(
                .setVideoPlayer(
                    .init(
                        anime: resumeWatching.animeStore,
                        selectedEpisode: Episode.ID(resumeWatching.episodeStore.number)
                    )
                )
            )

        case let .animeDetail(.play(anime, episodes, selected)):
            return .action(
                .setVideoPlayer(
                    .init(
                        anime: anime,
                        episodes: episodes,
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
                    await send(.videoPlayer(.saveState))
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
        case .appDelegate(.appDidFinishLaunching):
            return .run { send in
                let items = downloaderClient.observeFinished()

                for await item in items {
                    for (key, value) in item {
                        await send(.onDownloadFinished(key, value))
                        downloaderClient.remove(key)
                    }
                }
            }

        case .setModalOverlay(let overlay):
            state.modalOverlay = overlay

        case .collection(.onAddNewCollectionTapped):
            return .action(.setModalOverlay(.addNewCollection(.init())), animation: .spring(response: 0.35, dampingFraction: 1))

        case .animeDetail(.downloadEpisode(let episodeId)):
            guard let animeId = state.animeDetail?.animeId else { break }
            return .action(
                .setModalOverlay(.downloadOptions(.init(animeId: animeId, episodeNumber: episodeId))),
                animation: .spring(response: 0.35, dampingFraction: 1)
            )

        case .onDownloadFinished(let item, let location):
            return .run { _ in
                let animeStore = try await repositoryClient.fetch(AnimeStore.all.where(\AnimeStore.id == item.animeId)).first

                if var episode = animeStore?.episodes.first(where: { $0.number == item.episodeNumber }) {
                    episode.downloadURL = location
                    try await repositoryClient.insert(episode)
                }
            }

        case .modalOverlay(.downloadOptions(.downloadClicked)):
            var effects = [EffectTask<Action>]()

            if case let .downloadOptions(downloadState) = state.modalOverlay, let source = downloadState.source {
                effects.append(
                    .fireAndForget {
                        let downloadItem = DownloaderClient.Item(
                            animeId: downloadState.animeId,
                            episodeNumber: downloadState.episodeNumber,
                            source: source
                        )
                        _ = downloaderClient.download(downloadItem)
                    }
                )
            }

            effects.append(.action(.modalOverlay(.onClose)))
            return .merge(effects)

        case .modalOverlay(.addNewCollection(.saveTitle)):
            return .action(.modalOverlay(.onClose))

        case .modalOverlay(.onClose):
            return .action(.setModalOverlay(nil), animation: .spring(response: 0.35, dampingFraction: 1))

        default:
            break
        }
        return .none
    }
}
