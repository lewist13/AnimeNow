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
import VideoPlayerClient
import UserDefaultsClient
import ComposableArchitecture

public struct AnimePlayerReducer: ReducerProtocol {
    typealias LoadableEpisodes = Loadable<[AnyEpisodeRepresentable]>
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
                        return " Provider"
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

        var episodes = LoadableEpisodes.idle
        var sourcesOptions = LoadableSourcesOptions.idle
        var animeStore = Loadable<AnimeStore>.idle
        var skipTimes = Loadable<[SkipTime]>.idle

        public var selectedEpisode: Episode.ID
        var selectedProvider: Provider.ID?
        var selectedSource: Source.ID?
        var selectedSidebar: Sidebar?
        var selectedSubtitle: Source.Subtitle.ID?

        var showPlayerOverlay = true

        // Internal

        var hasInitialized = false

        // Shared Player Properties

        let player: AVPlayer
        public fileprivate(set) var playerProgress: Double = 0.0
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
            anime: some AnimeRepresentable,
            episodes: [any EpisodeRepresentable]? = nil,
            selectedEpisode: Episode.ID
        ) {
            self.player = player
            self.anime = anime.eraseAsRepresentable()
            if let episodes = episodes {
                self.episodes = .success(episodes.map { $0.eraseAsRepresentable() })
            } else {
                self.episodes = .idle
            }
            self.selectedEpisode = selectedEpisode
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

        case selectEpisode(AnyEpisodeRepresentable.ID)
        case selectProvider(Provider.ID)
        case selectSource(Source.ID?)
        case selectSubtitle(Source.Subtitle.ID?)
        case selectAudio(Provider.ID)

        // MacOS Specific
        case isHoveringPlayer(Bool)
        case onMouseMoved

        // Internal Actions
        case showPlayerOverlay(Bool)
        case internalSetSidebar(Sidebar?)
        case closeSidebarAndShowControls
        case close

        case fetchedAnimeInfoStore([AnimeStore])
        case fetchedEpisodes(TaskResult<[Episode]>)
        case fetchSourcesOptions
        case fetchedSourcesOptions(TaskResult<SourcesOptions>)
        case fetchSkipTimes
        case fetchedSkipTimes(TaskResult<[SkipTime]>)

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
        if case .failed = episodes {
            return .error("There was an error retrieving episodes at this time. Please try again later.")
        } else if case .success(let episodes) = episodes, episodes.count == 0 {
            return .error("There are no available episodes as of this time. Please try again later.")
        } else if let episode = episode, episode.providers.count == 0 {
            return .error("There are no providers available for this episode. Please try again later.")
        } else if case .failed = sourcesOptions {
            return .error("There was an error trying to retrieve sources. Please try again later.")
        } else if case .success(let sourcesOptions) = sourcesOptions, sourcesOptions.sources.count == 0 {
            return .error("There are currently no sources available for this episode. Please try again later.")
        } else if case .error = playerStatus {
            return .error("There was an error starting video player. Please try again later.")

        // Loading States
        } else if !episodes.finished {
            return .loading
        } else if (episode?.providers.count ?? 0) > 0 && !sourcesOptions.finished {
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
        if let episodes = episodes.value {
            return episodes[id: selectedEpisode]
        }

        return nil
    }

    var provider: Provider? {
        if let episode = episode, let selectedProvider = selectedProvider {
            return episode.providers.first(where: { $0.id == selectedProvider })
        }

        return nil
    }

    var source: Source? {
        if let selectedSource, let sources = sourcesOptions.value?.sources {
            return sources[id: selectedSource]
        }
        return nil
    }

    var nextEpisode: AnyEpisodeRepresentable? {
        if let episode,
           let episodes = episodes.value,
           let index = episodes.index(id: episode.id),
           (index + 1) < episodes.count {
            return episodes[index + 1]
        }
        return nil
    }

    var subtitle: Source.Subtitle? {
        if let selectedSubtitle, let subtitles = sourcesOptions.value?.subtitles {
            return subtitles[id: selectedSubtitle]
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
    struct FetchEpisodesCancellable: Hashable {}
    struct FetchSourcesCancellable: Hashable {}
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

                if !state.episodes.hasInitialized {
                    state.episodes = .loading
                    effects.append(
                        .run { send in
                            await send(
                                .fetchedEpisodes(
                                    .init {
                                        try await animeClient.getEpisodes(animeId)
                                    }
                                )
                            )
                        }
                            .cancellable(id: FetchEpisodesCancellable.self)
                    )
                } else if state.episode != nil {
                    effects.append(
                        .action(.selectEpisode(state.selectedEpisode))
                    )
                }

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
            return .concatenate(
                self.saveEpisodeState(state: state),
                .run { await videoPlayerClient.execute(.clear) },
                .cancel(id: VideoPlayerStatusCancellable.self),
                .cancel(id: VideoPlayerProgressCancellable.self),
                .cancel(id: ObserveFullScreenNotificationId.self),
                .cancel(id: HidePlayerOverlayDelayCancellable.self),
                .cancel(id: CancelAnimeStoreObservable.self),
                .cancel(id: CancelAnimeFetchId.self),
                .cancel(id: FetchSourcesCancellable.self),
                .cancel(id: FetchEpisodesCancellable.self),
                .cancel(id: FetchSkipTimesCancellable.self),
                .action(.close)
            )

        case .closeSidebar:
            return .action(
                .internalSetSidebar(nil),
                animation: .easeInOut(duration: 0.25)
            )

        case .selectEpisode(let episodeId):
            var effects = [Effect<Action, Never>]()

            // Before selecting episode, save progress

            effects.append(self.saveEpisodeState(state: state))

            state.selectedEpisode = episodeId

            let lastSelectedProvider = userDefaultsClient.get(.videoPlayerProvider)
            let lastSelectedIsDub = userDefaultsClient.get(.videoPlayerAudioIsDub)

            var providerId = state.episode?.providers.first(
                where: { $0.description == lastSelectedProvider && $0.dub == lastSelectedIsDub }
            )?.id

            providerId = providerId ?? state.episode?.providers.first(
                where: { $0.dub == lastSelectedIsDub }
            )?.id

            providerId = providerId ?? state.episode?.providers.first(
                where: { $0.description == lastSelectedProvider }
            )?.id

            providerId = providerId ?? state.episode?.providers.first?.id

            effects.append(self.internalSetProvider(providerId, state: &state))
            effects.append(.action(.fetchSkipTimes))

            return .concatenate(effects)

        case .selectProvider(let providerId):
            guard let providerName = state.episode?.providers[id: providerId]?.description else { break }
            guard providerName != state.provider?.description else { break }

            let lastSelectedIsDub = userDefaultsClient.get(.videoPlayerAudioIsDub)

            var providerId = state.episode?.providers.first(where: { $0.description == providerName && $0.dub == lastSelectedIsDub })?.id
            providerId = providerId ?? state.episode?.providers.first(where: { $0.description == providerName })?.id

            guard let providerId = providerId else { break }

            return .concatenate(
                self.saveEpisodeState(state: state),
                self.internalSetProvider(providerId, state: &state)
            )

        case .selectSource(let sourceId):
            return .concatenate(
                self.saveEpisodeState(state: state),
                self.internalSetSource(sourceId, state: &state)
            )

        case .selectSubtitle(let subtitleId):
            state.selectedSubtitle = subtitleId

            let subtitle = state.subtitle?.lang
            return .run {
                await userDefaultsClient.set(.videoPlayerSubtitle, value: subtitle)
            }

        case .selectSidebarSettings(let section):
            return .action(.sidebarSettingsSection(section))
                .animation(.easeInOut(duration: 0.25))

        case .selectAudio(let providerId):
            guard providerId != state.provider?.id else { break }
            guard let provider = state.episode?.providers[id: providerId] else { break }

            return .concatenate(
                .run {
                    await userDefaultsClient.set(.videoPlayerAudioIsDub, value: provider.dub)
                },
                self.saveEpisodeState(state: state),
                self.internalSetProvider(providerId, state: &state)
            )

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

        case .fetchedEpisodes(.success(let episodes)):
            state.episodes = .success(episodes.map({ $0.eraseAsRepresentable() }))
            let selectedEpisodeId = state.selectedEpisode
            return .action(.selectEpisode(selectedEpisodeId))

        case .fetchedEpisodes(.failure):
            state.episodes = .failed

        // Fetch SourcesOptions

        case .fetchSourcesOptions:
            guard let provider = state.provider else {
                return self.internalSetSource(nil, state: &state)
            }

            state.sourcesOptions = .loading

            return .concatenate(
                self.internalSetSource(nil, state: &state),
                .run {
                    await .fetchedSourcesOptions(
                        .init { try await animeClient.getSources(provider) }
                    )
                }
                .cancellable(id: FetchSourcesCancellable.self, cancelInFlight: true)
            )

        case .fetchedSourcesOptions(.success(let sources)):
            state.sourcesOptions = .success(sources)

            let lastSelectedQuality = userDefaultsClient.get(.videoPlayerQuality)
            let lastSelectedSubtitles = userDefaultsClient.get(.videoPlayerSubtitle)

            let sourceId = sources.sources.first(where: { $0.quality == lastSelectedQuality })?.id ?? sources.sources.first?.id
            let subtitleId = sources.subtitles.first(where: { $0.lang == lastSelectedSubtitles })?.id ?? nil

            state.selectedSubtitle = subtitleId

            return self.internalSetSource(sourceId, state: &state)

        case .fetchedSourcesOptions(.failure):
            state.sourcesOptions = .failed
            state.selectedSource = nil
            return self.internalSetSource(nil, state: &state)

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

        case .fetchedSkipTimes(.success(let skipTimes)):
            state.skipTimes = .success(skipTimes)

        case .fetchedSkipTimes(.failure(let error)):
            Logger.log(.error, error.localizedDescription)
            state.skipTimes = .failed

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
            return .run {
                await videoPlayerClient.execute(.seekTo(requestedTime))
            }

        case .forwardsTapped:
            guard state.playerDuration > 0.0 else { break }
            let progress = state.playerProgress + 15 / state.playerDuration

            let requestedTime = min(progress, 1.0)
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
                return .run { _ in
                    await videoPlayerClient.execute(.seekTo(savedEpisodeProgress.progress ?? .zero))
                    await videoPlayerClient.execute(.resume)
                }
            } else {
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

        case .binding:
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

    private func internalSetSource(_ sourceId: Source.ID?, state: inout State) -> EffectTask<Action> {
        state.selectedSource = sourceId

        if let source = state.source {
            let episodeTitle = state.episode?.title ?? "Episode \(state.selectedEpisode)"
            let animeTitle = state.anime.title
            let thumbnail = (state.episode?.thumbnail ?? state.anime.posterImage.largest)?.link
            return .run { _ in
                await userDefaultsClient.set(.videoPlayerQuality, value: source.quality)
                await videoPlayerClient.execute(
                    .play(
                        source.url,
                        .init(
                            videoTitle: episodeTitle,
                            videoAuthor: animeTitle,
                            thumbnail: thumbnail
                        )
                    )
                )
            }
        } else {
            return .run {
                await videoPlayerClient.execute(.clear)
            }
        }
    }

    private func internalSetProvider(_ providerId: Provider.ID?, state: inout State) -> EffectTask<Action> {
        state.selectedProvider = providerId
        state.sourcesOptions = .idle

        let provider = state.provider?.description

        return .run { send in
            if let provider {
                await userDefaultsClient.set(.videoPlayerProvider, value: provider)
            }

            await send(.fetchSourcesOptions)
        }
    }

    private func saveEpisodeState(state: State) -> EffectTask<Action> {
        let episodeId = state.selectedEpisode
        guard let episode = state.episodes.value?[id: episodeId] else { return .none }
        guard state.playerDuration > 0 else { return .none }
        guard var animeStore = state.animeStore.value else { return .none }

        let progress = state.playerProgress

        animeStore.updateProgress(
            for: episode,
            progress: progress
        )

        return .fireAndForget { [animeStore] in
            try await databaseClient.insert(animeStore)
        }
    }
}
