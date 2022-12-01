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

        var totalDownloadsCount = 0
    }

    enum Action: BindableAction {
        case onAppear
        case setVideoPlayer(AnimePlayerReducer.State?)
        case setAnimeDetail(AnimeDetailReducer.State?)
        case setModalOverlay(ModalOverlayReducer.State?)
        case setDownloadingCount(Int)
        case onDownloadFinished(DownloaderClient.Request, URL)
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

        case let .downloads(.playEpisode(anime, episodes, selected)):
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
//            struct OnEpisodeDownloadFinished: Hashable { }
            return .merge(
                .run { send in
                    let items = downloaderClient.onFinish()

                    for await item in items {
                        await send(.onDownloadFinished(item.0, item.1))
                    }
                },
                .run { send in
                    let downloadCounts = downloaderClient.observeCount()

                    for await count in downloadCounts {
                        await send(.setDownloadingCount(count))
                    }
                }
            )

        case .setModalOverlay(let overlay):
            state.modalOverlay = overlay

        case .setDownloadingCount(let count):
            state.totalDownloadsCount = count

        case .collection(.onAddNewCollectionTapped):
            return .action(.setModalOverlay(.addNewCollection(.init())), animation: .spring(response: 0.35, dampingFraction: 1))

        case .animeDetail(.downloadEpisode(let episode)):
            guard let anime = state.animeDetail?.anime.value else { break }
            return .action(
                .setModalOverlay(.downloadOptions(.init(anime: anime, episode: episode))),
                animation: .spring(response: 0.35, dampingFraction: 1)
            )

        case .onDownloadFinished(let item, let location):
            return .run { send in
                let animeStores = try await repositoryClient.fetch(AnimeStore.all.where(\AnimeStore.id == item.anime.id))

                if var animeStore = animeStores[id: item.anime.id] {
                    if let episode = animeStore.episodes.first(where: { $0.number == item.episode.number }) {
                        try await repositoryClient.update(episode.id, \EpisodeStore.downloadURL, location)
                    } else {
                        var episode = EpisodeStore.findOrCreate(item.episode, animeStore.episodes)
                        episode.downloadURL = location
                        animeStore.episodes.insert(episode)
                        try await repositoryClient.insert(animeStore)
                    }
                } else {
                    var animeStore = AnimeStore.findOrCreate(item.anime, animeStores)
                    var episode = EpisodeStore.findOrCreate(item.episode, animeStore.episodes)
                    episode.downloadURL = location
                    animeStore.episodes.insert(episode)
                    try await repositoryClient.insert(animeStore)
                }
            }

        case .modalOverlay(.downloadOptions(.downloadClicked)):
            var effects = [EffectTask<Action>]()

            if case let .downloadOptions(downloadState) = state.modalOverlay, let source = downloadState.source {
                effects.append(
                    .fireAndForget {
                        let downloadItem = DownloaderClient.Request(
                            anime: downloadState.anime,
                            episode: downloadState.episode,
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
