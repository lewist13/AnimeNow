//
//  AppReducer.swift
//  Anime Now!
//
//  Created by ErrorErrorError on 9/4/22.
//  Copyright © 2022. All rights reserved.
//

import SwiftUI

import HomeFeature
import SearchFeature
import SettingsFeature
import DownloadsFeature
import AnimePlayerFeature
import ModalOverlayFeature
import CollectionsFeature
import AnimeDetailFeature

import DatabaseClient
import DiscordClient
import DownloaderClient
import VideoPlayerClient

import SharedModels

import ComposableArchitecture

public struct AppReducer: ReducerProtocol {
    public init() { }

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

    public struct State: Equatable {
        @BindableState var route = Route.home

        var appDelegate = AppDelegateReducer.State()

        var home = HomeReducer.State()
        var collection = CollectionsReducer.State()
        var search = SearchReducer.State()
        var downloads = DownloadsReducer.State()
        public var settings = SettingsReducer.State()

        var videoPlayer: AnimePlayerReducer.State?
        var animeDetail: AnimeDetailReducer.State?
        var modalOverlay: ModalOverlayReducer.State?

        var totalDownloadsCount = 0

        var animeProviders = [ProviderInfo]()

        public init() { }
    }

    public enum Action: BindableAction {
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
        case fetchedAnimeProviders(TaskResult<[ProviderInfo]>)
        case binding(BindingAction<State>)
    }

    @Dependency(\.apiClient) var apiClient
    @Dependency(\.mainQueue) var mainQueue
    @Dependency(\.discordClient) var discordClient
    @Dependency(\.databaseClient) var databaseClient
    @Dependency(\.videoPlayerClient) var videoPlayerClient
    @Dependency(\.downloaderClient) var downloaderClient

    public var body: some ReducerProtocol<State, Action> {
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
    public var hasPendingChanges: Bool {
        videoPlayer != nil
    }
}

extension AppReducer {
    func core(state: inout State, action: Action) -> EffectTask<Action> {
        switch action {

        case .setVideoPlayer(let item):
            state.videoPlayer = item
            if item == nil {
                print("Close player")
                return .run {
                    await discordClient.setActivity(nil)
                }
            }

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
                        anime: anime,
                        availableProviders: state.animeProviders
                    )
                ),
                animation: .interactiveSpring(response: 0.35, dampingFraction: 1.0)
            )

        case let .collection(.onAnimeTapped(anime)):
            return .action(
                .setAnimeDetail(
                    .init(
                        anime: anime,
                        availableProviders: state.animeProviders
                    )
                ),
                animation: .interactiveSpring(response: 0.35, dampingFraction: 1.0)
            )

        case let .home(.anyAnimeTapped(anime)):
            return .action(
                .setAnimeDetail(
                    .init(
                        anime: anime,
                        availableProviders: state.animeProviders
                    )
                ),
                animation: .interactiveSpring(response: 0.35, dampingFraction: 1.0)
            )

        case let .home(.resumeWatchingTapped(resumeWatching)):
            return .action(
                .setVideoPlayer(
                    .init(
                        player: videoPlayerClient.player(),
                        anime: resumeWatching.animeStore,
                        availableProviders: .init(items: state.animeProviders),
                        selectedEpisode: Episode.ID(resumeWatching.episodeStore.number)
                    )
                )
            )

        case let .animeDetail(.play(anime, streamingProvider, selected)):
            return .action(
                .setVideoPlayer(
                    .init(
                        player: videoPlayerClient.player(),
                        anime: anime,
                        availableProviders: .init(items: state.animeProviders, selected: streamingProvider.name),
                        streamingProvider: streamingProvider,
                        selectedEpisode: selected
                    )
                )
            )

        case let .downloads(.playEpisode(anime, episodes, selected)):
            return .action(
                .setVideoPlayer(
                    .init(
                        player: videoPlayerClient.player(),
                        anime: anime,
                        availableProviders: .init(items: [.init(name: "Offline")], selected: "Offline"),
                        streamingProvider: .init(
                            name: "Offline",
                            episodes: episodes.map { .init(title: $0.title, number: $0.number, description: "", isFiller: false, links: $0.links) }
                        ),
                        selectedEpisode: selected
                    )
                )
            )

        case .animeDetail(.close):
            return .action(
                .setAnimeDetail(nil),
                animation: .easeInOut(duration: 0.25)
            )

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
            return .merge(
                .run { send in
                    let downloadCounts = downloaderClient.count()

                    for await count in downloadCounts {
                        await send(.setDownloadingCount(count))
                    }
                },
                .run {
                    await .fetchedAnimeProviders(
                        TaskResult { try await apiClient.request(.consumetAPI, .listProviders(of: .ANIME)) }
                    )
                }
            )

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

        case .animeDetail(.downloadEpisode(let episodeId)):
            guard let availableProviders = state.animeDetail?.stream.availableProviders,
                  let anime = state.animeDetail?.anime.value else { break }
            return .action(
                .setModalOverlay(
                    .downloadOptions(
                        .init(
                            anime: anime,
                            episodeId: episodeId,
                            availableProviders: availableProviders
                        )
                    )
                ),
                animation: .spring(response: 0.35, dampingFraction: 1)
            )

        case .animeDetail(.showCollectionsList(let animeId, let collections)):
            return .action(
                .setModalOverlay(
                    .editCollection(
                        .init(
                            animeId: animeId,
                            collections: collections
                        )
                    )
                ),
                animation: .spring(response: 0.35, dampingFraction: 1)
            )

        case .animeDetail(.fetchedCollectionStores(let collections)):
            if case .some(.editCollection(var collectionState)) = state.modalOverlay {
                collectionState.collections = .init(collections)
                state.modalOverlay = .editCollection(collectionState)
            }

        case .modalOverlay(.downloadOptions(.downloadClicked)):
            if case let .downloadOptions(downloadState) = state.modalOverlay,
               let episode = downloadState.stream.episode?.eraseAsRepresentable(),
               let source = downloadState.stream.source {
                let downloadItem = DownloaderClient.Request(
                    anime: downloadState.anime,
                    episode: episode,
                    source: source
                )
                downloaderClient.download(downloadItem)

                return .action(.modalOverlay(.onClose))
            }

        case .modalOverlay(.addNewCollection(.saveTitle)):
            return .action(.modalOverlay(.onClose))

        case .modalOverlay(.editCollection(.collectionSelectedToggle(let collectionStoreId))):
            if var collection = state.animeDetail?.collectionStores.value?[id: collectionStoreId],
                let anime = state.animeDetail?.animeStore.value {
                if collection.animes[id: anime.id] != nil {
                    collection.animes[id: anime.id] = nil
                } else {
                    collection.animes[id: anime.id] = anime
                }

                return .run { [collection] in
                    try await databaseClient.insert(collection)
                }
            }

        case .modalOverlay(.onClose):
            return .action(.setModalOverlay(nil), animation: .spring(response: 0.35, dampingFraction: 1))

        case .fetchedAnimeProviders(.success(let providers)):
            state.animeProviders = providers

        case .fetchedAnimeProviders(.failure(let error)):
            state.animeProviders = []
            print(error)

        default:
            break
        }

        return .none
    }
}
