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
        var downloads = DownloadsReducer.State()
        var settings = SettingsReducer.State()

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
            return .run { send in
                let downloadCounts = downloaderClient.count()

                for await count in downloadCounts {
                    await send(.setDownloadingCount(count))
                }
            }

        case .setModalOverlay(let overlay):
            state.modalOverlay = overlay

        case .setDownloadingCount(let count):
            state.totalDownloadsCount = count

        case .collection(.onAddNewCollectionTapped):
            return .action(
                .setModalOverlay(
                    .addNewCollection(
                        .init()
                    )
                ),
                animation: .spring(response: 0.35, dampingFraction: 1)
            )

        case .animeDetail(.downloadEpisode(let episode)):
            guard let anime = state.animeDetail?.anime.value else { break }
            return .action(
                .setModalOverlay(
                    .downloadOptions(
                        .init(
                            anime: anime,
                            episode: episode
                        )
                    )
                ),
                animation: .spring(response: 0.35, dampingFraction: 1)
            )

        case .animeDetail(.showCollectionsList(let animeId, let collections)):
            return .action(
                .setModalOverlay(
                    .collectionList(
                        .init(
                            animeId: animeId,
                            collections: collections
                        )
                    )
                ),
                animation: .spring(response: 0.35, dampingFraction: 1)
            )

        case .animeDetail(.fetchedCollectionStores(let collections)):
            if case .some(.collectionList(var collectionState)) = state.modalOverlay {
                collectionState.collections = .init(collections)
                state.modalOverlay = .collectionList(collectionState)
            }

        case .modalOverlay(.downloadOptions(.downloadClicked)):
            if case let .downloadOptions(downloadState) = state.modalOverlay, let source = downloadState.source {
                let downloadItem = DownloaderClient.Request(
                    anime: downloadState.anime.eraseAsRepresentable(),
                    episode: downloadState.episode.eraseAsRepresentable(),
                    source: source
                )
                downloaderClient.download(downloadItem)

                return .action(.modalOverlay(.onClose))
            }

        case .modalOverlay(.addNewCollection(.saveTitle)):
            return .action(.modalOverlay(.onClose))

        case .modalOverlay(.collectionList(.collectionSelectedToggle(let collectionStoreId))):
            if var collection = state.animeDetail?.collectionStores.value?[id: collectionStoreId],
                let anime = state.animeDetail?.animeStore.value {
                if collection.animes[id: anime.id] != nil {
                    collection.animes[id: anime.id] = nil
                } else {
                    collection.animes[id: anime.id] = anime
                }

                return .run { [collection] in
                    try await repositoryClient.insert(collection)
                }
            }

        case .modalOverlay(.onClose):
            return .action(.setModalOverlay(nil), animation: .spring(response: 0.35, dampingFraction: 1))

        default:
            break
        }

        return .none
    }
}
