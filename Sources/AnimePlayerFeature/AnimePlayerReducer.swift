//
//  AnimePlayerReducer.swift
//  Anime Now!
//
//  Created by ErrorErrorError on 10/1/22.
//  Copyright © 2022. All rights reserved.
//

import Logger
import SwiftUI
import Utilities
import Foundation
import AnimeClient
import AVFoundation
import SharedModels
import DatabaseClient
import ViewComponents
import AnimeStreamLogic
import VideoPlayerClient
import UserDefaultsClient
import ComposableArchitecture

public struct AnimePlayerReducer: ReducerProtocol {
    typealias LoadableSourcesOptions = Loadable<SourcesOptions>

    public enum Sidebar: Hashable, CustomStringConvertible {
        case episodes
        case settings(SettingsState)
        case subtitles

        public var description: String {
            switch self {
            case .episodes:
                return "Episodes"
            case .settings:
                return "Settings"
            case .subtitles:
                return "Subtitles"
            }
        }

        public struct SettingsState: Hashable {
            public enum Section: Hashable, CustomStringConvertible {
                case provider
                case quality
                case audio
                case subtitleOptions

                public var description: String {
                    switch self {
                    case .provider:
                        return "Provider"
                    case .quality:
                        return "Quality"
                    case .audio:
                        return "Audio"
                    case .subtitleOptions:
                        return "Subtitle Options"
                    }
                }
            }

            var selectedSection: Section?
        }
    }

    public struct State: Equatable {
        public let anime: AnyAnimeRepresentable
        public var stream: AnimeStreamLogic.State

        var animeStore = Loadable<AnimeStore>.idle
        var skipTimes = Loadable<[SkipTime]>.idle

        var selectedSidebar: Sidebar? = nil

        var showPlayerOverlay = true

        // Internal

        var hasInitialized = false

        // Shared Player Properties

        let player: AVPlayer
        public var playerProgress: Double = 0.0
        var playerBuffered: Double { player.bufferProgress }
        public var playerDuration: Double { player.totalDuration }
        var playerStatus = VideoPlayerClient.Status.idle
        var playerIsFullScreen = false
        var playerVolume: Double { player.isMuted ? 0.0 : Double(player.volume) }
        var playerPiPStatus = VideoPlayer.PIPStatus.restoreUI
        @BindableState var playerPiPActive = false
        @BindableState var playerGravity = VideoPlayer.Gravity.resizeAspect

        public init(
            player: AVPlayer,
            anime: any AnimeRepresentable,
            availableProviders: Selectable<ProviderInfo>,
            streamingProvider: AnimeStreamingProvider? = nil,
            selectedEpisode: Episode.ID
        ) {
            self.player = player
            self.anime = anime.eraseAsRepresentable()
            self.stream = .init(
                animeId: anime.id,
                episodeId: selectedEpisode,
                availableProviders: availableProviders,
                streamingProviders: streamingProvider.flatMap { [$0] } ?? []
            )
        }
    }

    public enum Action: BindableAction {

        // View Actions

        case onAppear
        case playerTapped
        case closeButtonTapped

        case toggleEpisodes
        case toggleSettings
        case toggleSubtitles
        case selectSidebarSettings(Sidebar.SettingsState.Section?)
        case closeSidebar
        case saveState

        case stream(AnimeStreamLogic.Action)

        // MacOS Specific

        case isHoveringPlayer(Bool)
        case onMouseMoved

        // Internal Actions

        case showPlayerOverlay(Bool)
        case internalSetSidebar(Sidebar?)
        case closeSidebarAndShowControls
        case close

        case fetchedAnimeInfoStore([AnimeStore])
        case fetchSkipTimes
        case fetchedSkipTimes(Loadable<[SkipTime]>)

        // Sidebar Actions

        case sidebarSettingsSection(Sidebar.SettingsState.Section?)

        // Player Actions

        case togglePictureInPicture
        case play
        case pause
        case backwardsTapped
        case forwardsTapped
        case replayTapped
        case togglePlayback
        case startSeeking
        case stopSeeking
        case seeking(to: Double)
        case volume(to: Double)
        case toggleVideoGravity

        case playerStatus(VideoPlayerClient.Status)
        case playerProgress(Double)
        case playerPiPStatus(VideoPlayer.PIPStatus)
        case playerIsFullScreen(Bool)

        // Internal Video Player Actions

        case binding(BindingAction<State>)
    }

    @Dependency(\.mainQueue) var mainQueue
    @Dependency(\.mainRunLoop) var mainRunLoop
    @Dependency(\.animeClient) var animeClient
    @Dependency(\.databaseClient) var databaseClient
    @Dependency(\.videoPlayerClient) var videoPlayerClient
    @Dependency(\.userDefaultsClient) var userDefaultsClient

    public init() { }

    public var body: some ReducerProtocol<State, Action> {

        // Runs before changing video player state

        Reduce { state, action in
            let common: (inout State) -> EffectTask<Action> = { state in
                let copy = state
                state.playerProgress = .zero
                return self.saveEpisodeState(state: copy)
            }

            switch action {
            case .stream(.initialize):
                return .action(.fetchSkipTimes)

            case .stream(.selectEpisode):
                return .merge(
                    common(&state),
                    .action(.fetchSkipTimes),
                    .run {
                        await videoPlayerClient.execute(.clear)
                    }
                )

            case .stream(.selectProvider),
                    .stream(.selectLink),
                    .closeButtonTapped:
                return .merge(
                    common(&state),
                    .run {
                        await videoPlayerClient.execute(.clear)
                    }
                )

            case .stream(.selectSource):
                return common(&state)
                
            default:
                break
            }
            return .none
        }
        Scope(state: \.stream, action: /Action.stream) {
            AnimeStreamLogic()
        }
        BindingReducer()
        Reduce(self.core)
    }
}

// MARK: Status State

extension AnimePlayerReducer.State {
    enum Status: Equatable {
        case loading
        case playing
        case paused
        case replay
        case error(String)
    }

    var status: Status? {

        // Error States

        if stream.availableProviders.items.count == 0 {
            return .error("There are no available streaming providers at this time. Please try again later.")
//        } else if case .none = stream.availableProviders.item {
//            return .error("Please select a valid streaming provider.")
        } else if case .some(.failed) = stream.loadableStreamingProvider {
            return .error("There was an error retrieving episodes from selected streaming provider.")
        } else if case .some(.success(let item)) = stream.loadableStreamingProvider, item.episodes.count == 0 {
            return .error("There are no available episodes as of this time. Please try again later.")
        } else if case .failed = stream.sourceOptions {
            return .error("There was an error trying to retrieve sources. Please try again later.")
        } else if case .success(let sourcesOptions) = stream.sourceOptions, sourcesOptions.sources.count == 0 {
            return .error("There are currently no sources available for this episode. Please try again later.")
        } else if case .error = playerStatus {
            return .error("There was an error starting video player. Please try again later.")

        // Loading States

        } else if !(stream.loadableStreamingProvider?.finished ?? false) {
            return .loading
        } else if (episode?.links.count ?? 0) > 0 && !stream.sourceOptions.finished {
            return .loading
        } else if playerStatus == .finished ||  finishedWatching {
            return .replay
        } else if playerStatus == .idle || playerStatus == .loading || playerStatus == .playback(.buffering) {
            return .loading
        } else if playerStatus == .playback(.playing) {
            return .playing
        } else if playerStatus == .playback(.paused) {
            return .paused
        } else if case .loaded = playerStatus {
            return .paused
        }
        return nil
    }
}

// MARK: Episode Properties

extension AnimePlayerReducer.State {
    public var episode: AnyEpisodeRepresentable? {
        stream.episode?.eraseAsRepresentable()
    }

    var nextEpisode: Episode? {
        if let episode,
           let episodes = stream.streamingProvider?.episodes,
           let index = episodes.index(id: episode.id),
           (index + 1) < episodes.count {
            return episodes[index + 1]
        }
        return nil
    }
}

extension AnimePlayerReducer.State {
    var almostEnding: Bool {
        playerProgress >= 0.9
    }

    var finishedWatching: Bool {
        playerProgress >= 1.0
    }
}

extension AnimePlayerReducer.State {
    enum ActionType: Equatable {
        case skipRecap(to: Double)
        case skipOpening(to: Double)
        case skipEnding(to: Double)
        case nextEpisode(Episode.ID)

        var title: String {
            switch self {
            case .skipRecap:
                return "Skip Recap"
            case .skipOpening:
                return "Skip Opening"
            case .skipEnding:
                return "Skip Ending"
            case .nextEpisode:
                return "Next Episode"
            }
        }
    }

    var skipAction: ActionType? {
        if let skipTime = skipTimes.value?.first(where: { $0.isInRange(playerProgress) }) {
            switch skipTime.type {
            case .recap:
                return .skipRecap(to: skipTime.endTime)
            case .opening, .mixedOpening:
                return .skipOpening(to: skipTime.endTime)
            case .ending, .mixedEnding:
                return .skipEnding(to: skipTime.endTime)
            }
        } else if almostEnding, let nextEpisode = nextEpisode {
            return .nextEpisode(nextEpisode.id)
        }
        return nil
    }
}

extension AnimePlayerReducer {
    struct HidePlayerOverlayDelayCancellable: Hashable {}
    struct CancelAnimeStoreObservable: Hashable {}
    struct FetchSkipTimesCancellable: Hashable {}
    struct CancelAnimeFetchId: Hashable {}
    struct ObserveFullScreenNotificationId: Hashable {}
    struct VideoPlayerStatusCancellable: Hashable {}
    struct VideoPlayerProgressCancellable: Hashable {}

    func core(state: inout State, action: Action) -> EffectTask<Action> {
        switch action {

        // View Actions

        case .onAppear:
            let animeId = state.anime.id

            var effects = [EffectTask<Action>]()

            if !state.hasInitialized {
                state.hasInitialized = true

                effects.append(
                    .action(.stream(.initialize))
                )

                effects.append(
                    .run { send in
                        let animeStores: AsyncStream<[AnimeStore]> = databaseClient.observe(
                            AnimeStore.all
                                .where(\AnimeStore.id == animeId)
                                .limit(1)
                        )

                        for await animeStore in animeStores {
                            await send(.fetchedAnimeInfoStore(animeStore))
                        }
                    }
                        .cancellable(id: CancelAnimeStoreObservable.self)
                )

                #if os(macOS)
                effects.append(
                    .merge(
                        .run { send in
                            for await _ in await NotificationCenter.default.observeNotifications(
                                from: NSWindow.willEnterFullScreenNotification
                            ) {
                                await send(.playerIsFullScreen(true))
                            }
                        },
                        .run { send in
                            for await _ in await NotificationCenter.default.observeNotifications(
                                from: NSWindow.willExitFullScreenNotification
                            ) {
                                await send(.playerIsFullScreen(false))
                            }
                        }
                    )
                    .cancellable(id: ObserveFullScreenNotificationId.self)
                )
                #endif

                effects.append(
                    .run { send in
                        await withTaskCancellation(id: VideoPlayerStatusCancellable.self) {
                            for await status in videoPlayerClient.status() {
                                await send(.playerStatus(status))
                            }
                        }
                    }
                )

                effects.append(
                    .run { send in
                        await withTaskCancellation(id: VideoPlayerProgressCancellable.self) {
                            for await progress in videoPlayerClient.progress() {
                                await send(.playerProgress(progress))
                            }
                        }
                    }
                )
            }
            return .merge(effects)

        case .playerTapped:
            guard state.selectedSidebar == nil else {
                return .action(.closeSidebar)
            }

            guard !DeviceUtil.isMac else {
                break
            }

            let showingOverlay = !state.showPlayerOverlay

            var effects: [EffectTask<Action>] = [
                .action(.showPlayerOverlay(showingOverlay))
                .animation(AnimePlayerReducer.overlayVisibilityAnimation)
            ]

            if showingOverlay && state.playerStatus == .playback(.playing) {
                // Show overlay with timeout if the video is currently playing
                effects.append(
                    hideOverlayAnimationDelay()
                )
            } else {
                effects.append(
                    cancelHideOverlayAnimationDelay()
                )
            }

            return .concatenate(effects)

        // MacOS specific
        case .isHoveringPlayer(let isHovering):
            if isHovering {
                // TODO: fix issue when trying to select router
//                return .merge(
//                    .run { send in
//                        await send(
//                            .showPlayerOverlay(true),
//                            animation: AnimePlayerReducer.overlayVisibilityAnimation
//                        )
//                    },
//                    hideOverlayAnimationDelay()
//                )
            } else {
                return .merge(
                    .run { send in
                        await send(
                            .showPlayerOverlay(false),
                            animation: AnimePlayerReducer.overlayVisibilityAnimation
                        )
                    },
                    cancelHideOverlayAnimationDelay()
                )
            }

        case .onMouseMoved:
            var effects = [EffectTask<Action>]()

            if !state.showPlayerOverlay {
                effects.append(
                    .run { send in
                        await send(
                            .showPlayerOverlay(true),
                            animation: AnimePlayerReducer.overlayVisibilityAnimation
                        )
                    }
                )
            }

            effects.append(
                hideOverlayAnimationDelay()
            )

            return .merge(effects)

        case .toggleEpisodes:
            if case .episodes = state.selectedSidebar {
                return .action(
                    .internalSetSidebar(nil),
                    animation: .easeInOut(duration: 0.35)
                )
            } else {
                return .action(
                    .internalSetSidebar(.episodes),
                    animation: .easeInOut(duration: 0.35)
                )
            }

        case .toggleSettings:
            if case .settings = state.selectedSidebar {
                return .action(
                    .internalSetSidebar(nil),
                    animation: .easeInOut(duration: 0.35)
                )
            } else {
                return .action(
                    .internalSetSidebar(.settings(.init())),
                    animation: .easeInOut(duration: 0.35)
                )
            }

        case .toggleSubtitles:
            if case .subtitles = state.selectedSidebar {
                return .action(
                    .internalSetSidebar(nil),
                    animation: .easeInOut(duration: 0.35)
                )
            } else {
                return .action(
                    .internalSetSidebar(.subtitles),
                    animation: .easeInOut(duration: 0.35)
                )
            }

        case .closeButtonTapped:
            return .merge(
                .cancel(id: VideoPlayerStatusCancellable.self),
                .cancel(id: VideoPlayerProgressCancellable.self),
                .cancel(id: ObserveFullScreenNotificationId.self),
                .cancel(id: HidePlayerOverlayDelayCancellable.self),
                .cancel(id: CancelAnimeStoreObservable.self),
                .cancel(id: CancelAnimeFetchId.self),
                .cancel(id: FetchSkipTimesCancellable.self),
                .action(.close)
            )

        case .closeSidebar:
            return .action(
                .internalSetSidebar(nil),
                animation: .easeInOut(duration: 0.25)
            )

        case .selectSidebarSettings(let section):
            return .action(.sidebarSettingsSection(section))
                .animation(.easeInOut(duration: 0.25))

        case .showPlayerOverlay(let show):
            state.showPlayerOverlay = show

        // Internal Actions

        case .closeSidebarAndShowControls:
            state.selectedSidebar = nil
            return .action(.showPlayerOverlay(true))

        case .internalSetSidebar(let route):
            state.selectedSidebar = route

            if route != nil {
                return .merge(
                    self.cancelHideOverlayAnimationDelay(),
                    .action(.showPlayerOverlay(false))
                )
            }

        case .close:
            break

        // Section actions

        case .sidebarSettingsSection(let section):
            if case .settings = state.selectedSidebar {
                state.selectedSidebar = .settings(.init(selectedSection: section))
            }

        // Fetched Anime Store

        case .fetchedAnimeInfoStore(let animeStores):
            state.animeStore = .success(.findOrCreate(state.anime, animeStores))

        // Fetch Skip Times

        case .fetchSkipTimes:
            guard let episode = state.episode, let malId = state.anime.malId else {
                return .action(.fetchedSkipTimes(.success([])))
            }

            state.skipTimes = .loading

            let episodeNumber = episode.number
            return .run { [malId, episodeNumber] in
                await .fetchedSkipTimes(
                    .init { try await animeClient.getSkipTimes(malId, episodeNumber) }
                )
            }
            .cancellable(id: FetchSkipTimesCancellable.self, cancelInFlight: true)

        case .fetchedSkipTimes(let loadable):
            state.skipTimes = loadable

        // Video Player Actions

        case .play:
            return .run {
                await videoPlayerClient.execute(.resume)
            }

        case .pause:
            return .run {
                await videoPlayerClient.execute(.pause)
            }

        case .togglePictureInPicture:
            state.playerPiPActive.toggle()

        case .backwardsTapped:
            guard state.playerDuration > 0.0 else { break }
            let progress = state.playerProgress - 15 / state.playerDuration
            let requestedTime = max(progress, .zero)
            state.playerProgress = requestedTime
            return .run {
                await videoPlayerClient.execute(.seekTo(requestedTime))
            }

        case .forwardsTapped:
            guard state.playerDuration > 0.0 else { break }
            let progress = state.playerProgress + 15 / state.playerDuration
            let requestedTime = min(progress, 1.0)
            state.playerProgress = requestedTime
            return .run {
                await videoPlayerClient.execute(.seekTo(requestedTime))
            }

        case .toggleVideoGravity:
            switch state.playerGravity {
            case .resizeAspect:
                state.playerGravity = .resizeAspectFill

            default:
                state.playerGravity = .resizeAspect
            }
            return hideOverlayAnimationDelay()

        // Internal Video Player

        case .replayTapped:
            state.playerProgress = 0
            return .run { _ in
                await videoPlayerClient.execute(.seekTo(0))
                await videoPlayerClient.execute(.resume)
            }

        case .togglePlayback:
            if case .playing = state.status {
                return .run {
                    await videoPlayerClient.execute(.pause)
                }
            } else {
                return .run {
                    await videoPlayerClient.execute(.resume)
                }
            }

        case .startSeeking:
            return .run {
                await videoPlayerClient.execute(.pause)
            }

        case .seeking(to: let to):
            let clamped = min(1.0, max(0.0, to))
            state.playerProgress = clamped
            return .run {
                await videoPlayerClient.execute(.seekTo(clamped))
            }

        case .stopSeeking:
            return .run { _ in
                await videoPlayerClient.execute(.resume)
            }

        case .volume(to: let volume):
            let clamped = min(1.0, max(0.0, volume))

            return .merge(
                .run {
                    await videoPlayerClient.execute(.volume(clamped))
                },
                hideOverlayAnimationDelay()
            )

        // Player Actions Observer

        case .playerStatus(.finished):
            state.playerStatus = .finished
            return self.saveEpisodeState(state: state)

        case .playerStatus(.loaded(let duration)):
            state.playerStatus = .loaded(duration: duration)

            // First time duration is set and is not zero, resume progress
            if let animeInfo = state.animeStore.value,
               let episode = state.episode,
               let savedEpisodeProgress = animeInfo.episodes.first(where: { $0.number ==  episode.number }),
               !savedEpisodeProgress.almostFinished {
                state.playerProgress = savedEpisodeProgress.progress ?? .zero
                return .run { _ in
                    await videoPlayerClient.execute(.seekTo(savedEpisodeProgress.progress ?? .zero))
                    await videoPlayerClient.execute(.resume)
                }
            } else {
                state.playerProgress = .zero
                return .run { _ in
                    await videoPlayerClient.execute(.seekTo(.zero))
                    await videoPlayerClient.execute(.resume)
                }
            }

        case .playerStatus(let status):
            state.playerStatus = status

            guard !DeviceUtil.isMac else { break }

            if case .playback(.playing) = status, state.showPlayerOverlay {
                return hideOverlayAnimationDelay()
            } else if state.showPlayerOverlay {
                return cancelHideOverlayAnimationDelay()
            }

        case .playerProgress(let progress):
            state.playerProgress = progress

        case .playerPiPStatus(let status):
            state.playerPiPStatus = status

            if status == .willStop {
                return self.saveEpisodeState(state: state)
            }

        case .playerIsFullScreen(let fullscreen):
            state.playerIsFullScreen = fullscreen

        case .saveState:
            return self.saveEpisodeState(state: state)

        case .stream(.selectSource), .stream(.fetchedSources(.success)):
            if let source = state.stream.source {
                let anime = state.anime
                let episode = state.episode
                let episodeNumber = state.stream.selectedEpisode
                return .run {
                    await videoPlayerClient.execute(
                        .play(
                            .init(
                                source: source,
                                metadata: .init(
                                    videoTitle: episode?.title ?? "Episode \(episodeNumber)",
                                    videoAuthor: anime.title,
                                    thumbnail: (episode?.thumbnail ?? anime.posterImage.largest)?.link
                                )
                            )
                        )
                    )
                }
            }

        case .binding:
            break

        case .stream:
            break
        }

        return .none
    }
}

extension AnimePlayerReducer {
    static let overlayVisibilityAnimation = Animation.easeInOut(
        duration: 0.3
    )

    // Internal Effects

    private func hideOverlayAnimationDelay() -> EffectTask<Action> {
        return .run { send in
            try await withTaskCancellation(id: HidePlayerOverlayDelayCancellable.self, cancelInFlight: true) {
                try await self.mainQueue.sleep(for: .seconds(2.5))
                await send(
                    .showPlayerOverlay(false),
                    animation: AnimePlayerReducer.overlayVisibilityAnimation
                )
            }
        }
    }

    private func cancelHideOverlayAnimationDelay() -> EffectTask<Action> {
        .cancel(id: HidePlayerOverlayDelayCancellable.self)
    }

    private func saveEpisodeState(state: State, episodeId: Episode.ID? = nil) -> EffectTask<Action> {
        let episodeId = episodeId ?? state.stream.selectedEpisode
        guard let episode = state.stream.streamingProvider?.episodes[id: episodeId] else { return .none }
        guard state.playerDuration > 0 else { return .none }
        guard var animeStore = state.animeStore.value else { return .none }

        let progress = state.playerProgress

        animeStore.updateProgress(
            for: episode,
            progress: progress
        )

        return .run { [animeStore] in
            try await databaseClient.insert(animeStore)
        }
    }
}
