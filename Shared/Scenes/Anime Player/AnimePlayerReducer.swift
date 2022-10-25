//
//  AnimePlayerReducer.swift
//  Anime Now!
//
//  Created by ErrorErrorError on 10/1/22.
//  Copyright © 2022. All rights reserved.
//

import Foundation
import ComposableArchitecture
import AVFoundation
import SwiftUI

struct AnimePlayerReducer: ReducerProtocol {
    enum Sidebar: Hashable, CustomStringConvertible {
        case episodes
        case settings(SettingsState)
        case subtitles

        var description: String {
            switch self {
            case .episodes:
                return "Episodes"
            case .settings:
                return "Settings"
            case .subtitles:
                return "Subtitles"
            }
        }

        struct SettingsState: Hashable {
            enum Section: Hashable {
                case provider
                case quality
                case language
            }

            var selectedSection: Section?
        }
    }

    struct State: Equatable {
        let anime: AnyAnimeRepresentable

        var episodes = LoadableState<[AnyEpisodeRepresentable]>.idle
        var sources = LoadableState<[Source]>.idle
        var animeStore = LoadableState<AnimeStore>.idle
        var skipTimes = LoadableState<[SkipTime]>.idle

        var selectedEpisode: Episode.ID
        var selectedProvider: Provider.ID?
        var selectedSource: Source.ID?
        var selectedSidebar: Sidebar?
//        var playerSelectedSubtitle: AVMediaSelectionOption?

        var showPlayerOverlay = true

        // Internal

        var hasInitialized = false

        // Shared Player Properties

        @BindableState var playerAction: VideoPlayer.Action? = nil
        var playerProgress = Double.zero
        var playerBuffered = Double.zero
        var playerDuration = Double.zero
        var playerStatus = VideoPlayer.Status.idle
        var playerPiPStatus = VideoPlayer.PIPStatus.restoreUI
//        var playerSubtitles: AVMediaSelectionGroup?

        // MacOS Properties

        var playerVolume = 0.0

        init(
            anime: AnyAnimeRepresentable,
            episodes: [AnyEpisodeRepresentable]? = nil,
            selectedEpisode: Episode.ID
        ) {
            self.anime = anime
            if let episodes = episodes {
                self.episodes = .success(episodes)
            } else {
                self.episodes = .idle
            }
            self.selectedEpisode = selectedEpisode
        }
    }

    enum Action: Equatable, BindableAction {

        // View Actions

        case onAppear
        case playerTapped
        case isHoveringPlayer(Bool)
        case closeButtonTapped

        case showEpisodesSidebar
        case showSettingsSidebar
        case showSubtitlesSidebar
        case selectSidebarSettings(Sidebar.SettingsState.Section?)
        case closeSidebar

        case selectEpisode(Episode.ID, saveProgress: Bool = true)
        case selectProvider(Provider.ID?, saveProgress: Bool = true)
        case selectSource(Source.ID?, saveProgress: Bool = true)
//        case selectSubtitle(AVMediaSelectionOption)

        case showPlayerOverlay(Bool)

        // Internal Actions

        case initializeFirstTime
        case saveEpisodeProgress(AnyEpisodeRepresentable.ID?)
        case setSidebar(Sidebar?)
        case closeSidebarAndShowControls
        case hideOverlayAnimationDelay
        case cancelHideOverlayAnimationDelay
        case close

        case fetchedAnimeInfoStore([AnimeStore])
        case fetchEpisodes
        case fetchedEpisodes([Episode])
        case fetchSources
        case fetchedSources(TaskResult<[Source]>)
        case fetchSkipTimes
        case fetchedSkipTimes(TaskResult<[SkipTime]>)

        // Sidebar Actions

        case sidebarSettingsSection(Sidebar.SettingsState.Section?)

        // Player Actions

        case togglePictureInPicture
        case play
        case backwardsTapped
        case forwardsTapped
        case replayTapped
        case togglePlayback
        case startSeeking
        case stopSeeking
        case seeking(to: Double)
        case volume(to: Double)

        case playerStatus(VideoPlayer.Status)
        case playerAction(VideoPlayer.Action)
        case playerProgress(Double)
        case playerDuration(Double)
        case playerBuffer(Double)
        case playerPiPStatus(VideoPlayer.PIPStatus)
        case playerPlayedToEnd
//        case playerSubtitles(AVMediaSelectionGroup?)
//        case playerSelectedSubtitle(AVMediaSelectionOption?)
        case playerVolume(Double)
        case stopAndClearPlayer

        // Internal Video Player Actions

        case binding(BindingAction<State>)
    }

    @Dependency(\.animeClient) var animeClient
    @Dependency(\.mainQueue) var mainQueue
    @Dependency(\.mainRunLoop) var mainRunLoop
    @Dependency(\.repositoryClient) var repositoryClient
    @Dependency(\.userDefaultsClient) var userDefaultsClient
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
        } else if case .failed = sources {
            return .error("There was an error trying to retrieve sources. Please try again later.")
        } else if case .success(let sources) = sources, sources.count == 0 {
            return .error("There are currently no sources available for this episode. Please try again later.")
        } else if case .error = playerStatus {
            return .error("There was an error starting video player. Please try again later.")

        // Loading States
        } else if !episodes.finished {
            return .loading
        } else if (episode?.providers.count ?? 0) > 0 && !sources.finished {
            return .loading
        } else if finishedWatching {
            return .replay
        } else if playerStatus == .idle || playerStatus == .loading || playerStatus == .buffering {
            return .loading
        } else if playerStatus == .playing {
            return .playing
        } else if playerStatus == .paused || playerStatus == .readyToPlay {
            return .paused
        }
        return nil
    }
}

// MARK: Episode Properties

extension AnimePlayerReducer.State {
    var episode: AnyEpisodeRepresentable? {
        if let episodes = episodes.value {
            return episodes[id: selectedEpisode]
        }

        return nil
    }

    fileprivate var provider: Provider? {
        if let episode = episode, let selectedProvider = selectedProvider {
            return episode.providers.first(where: { $0.id == selectedProvider })
        }

        return nil
    }

    var source: Source? {
        if let sourceId = selectedSource, let sources = sources.value {
            return sources[id: sourceId]
        }
        return nil
    }

    var nextEpisode: AnyEpisodeRepresentable? {
        if let episode = episode,
           let episodes = episodes.value,
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
    struct FetchEpisodesCancellable: Hashable {}
    struct FetchSourcesCancellable: Hashable {}
    struct CancelAnimeStoreObservable: Hashable {}
    struct FetchSkipTimesCancellable: Hashable {}
    struct CancelAnimeFetchId: Hashable {}

    @ReducerBuilder<State, Action>
    var body: Reduce<State, Action> {
        BindingReducer()
        Reduce(self.core)
    }
    
    func core(state: inout State, action: Action) -> EffectTask<Action> {
        let overlayVisibilityAnimation = Animation.easeInOut(
            duration: 0.3
        )

        switch action {

        // View Actions

        case .onAppear:
            guard !state.hasInitialized else { break }
            return .task { .initializeFirstTime }

        case .playerTapped:
            guard state.selectedSidebar == nil else {
                return .task { .closeSidebar }
            }

            guard !DeviceUtil.isMac else {
                break
            }

            let showingOverlay = !state.showPlayerOverlay

            var effects: [EffectTask<Action>] = [
                .task { .showPlayerOverlay(showingOverlay) }
                    .animation(overlayVisibilityAnimation)
            ]

            if showingOverlay && state.playerStatus == .playing {
                // Show overlay with timeout if the video is currently playing
                effects.append(
                    .task { .hideOverlayAnimationDelay }
                )
            } else {
                effects.append(
                    .task { .cancelHideOverlayAnimationDelay }
                )
            }

            return .concatenate(effects)

        case .isHoveringPlayer(let hovering):
            if hovering {
                struct HideOverlayAnimationDebounce: Hashable { }
                return .concatenate(
                    .action(.showPlayerOverlay(true))
                        .animation(.easeInOut(duration: 0.15)),
                    .action(.hideOverlayAnimationDelay)
                        .debounce(id: HideOverlayAnimationDebounce(), for: 1, scheduler: mainQueue)
                )
            } else {
                return .merge(
                    .action(.showPlayerOverlay(false))
                        .animation(.easeInOut(duration: 0.15)),
                    .action(.cancelHideOverlayAnimationDelay)
                )
            }

        case .showEpisodesSidebar:
            return .task { .setSidebar(.episodes) }
                .animation(.easeInOut(duration: 0.35))

        case .showSettingsSidebar:
            return .task { .setSidebar(.settings(.init())) }
                .animation(.easeInOut(duration: 0.35))

        case .showSubtitlesSidebar:
            return .task { .setSidebar(.subtitles) }
                .animation(.easeInOut(duration: 0.35))

        case .closeButtonTapped:
            let selectedEpisodeId = state.selectedEpisode
            return .concatenate(
                .task { .saveEpisodeProgress(selectedEpisodeId) },
                .cancel(id: CancelAnimeStoreObservable()),
                .cancel(id: CancelAnimeFetchId()),
                .cancel(id: FetchSourcesCancellable()),
                .cancel(id: FetchEpisodesCancellable()),
                .cancel(id: FetchSkipTimesCancellable()),
                .cancel(id: HidePlayerOverlayDelayCancellable()),
                .task {
                    try await mainQueue.sleep(for: 0.25)
                    return .close
                }
            )

        case .closeSidebar:
            return .task { .setSidebar(nil) }
                .animation(.easeInOut(duration: 0.25))

        case .selectEpisode(let episodeId, let saveProgress):
            var effects = [Effect<Action, Never>]()

            // Before selecting episode, save progress

            if saveProgress {
                let episodeId = state.selectedEpisode
                effects.append(.task { .saveEpisodeProgress(episodeId) })
            }

            state.selectedEpisode = episodeId

            // TODO: Add user defaults for preferred provider or fallback to first
            let providerId = state.episode?.providers.first?.id

            effects.append(.task { .stopAndClearPlayer })
            effects.append(.task { .selectProvider(providerId, saveProgress: false) })
            effects.append(.task { .fetchSkipTimes })

            return .concatenate(effects)
            
        case .selectProvider(let providerId, let saveProgress):
            var effects = [Effect<Action, Never>]()

            // Before selecting provider, save progress

            if saveProgress {
                let episodeId = state.selectedEpisode
                effects.append(.task { [episodeId] in .saveEpisodeProgress(episodeId) })
            }

            state.selectedProvider = providerId

            effects.append(.task { .stopAndClearPlayer })
            effects.append(.task { .fetchSources })

            return .concatenate(effects)

        case .selectSource(let sourceId, let saveProgress):
            var effects = [Effect<Action, Never>]()

            // Before selecting source, save progress

            if saveProgress {
                let episodeId = state.selectedEpisode
                effects.append(.task { [episodeId] in .saveEpisodeProgress(episodeId) })
            }

            state.selectedSource = sourceId

            return .concatenate(effects)

        case .selectSidebarSettings(let section):
            return .task { .sidebarSettingsSection(section) }
                .animation(.easeInOut(duration: 0.25))

        case .showPlayerOverlay(let show):
            state.showPlayerOverlay = show

        // Internal Actions
    
        case .initializeFirstTime:
            state.hasInitialized = true

            let animeId = state.anime.id

            return .merge(
                .task { .fetchEpisodes },
                .run { [animeId] send in
                    let animeStores: AsyncStream<[AnimeStore]> = repositoryClient.observe(
                        .init(
                            format: "id == %d",
                            animeId
                        )
                    )

                    for await animeStore in animeStores {
                        await send(.fetchedAnimeInfoStore(animeStore))
                    }
                }
                    .cancellable(id: CancelAnimeStoreObservable())
            )

        case .hideOverlayAnimationDelay:
            return .task {
                try await self.mainQueue.sleep(for: 2.5)
                return .showPlayerOverlay(false)
            }
            .animation(overlayVisibilityAnimation)
            .cancellable(id: HidePlayerOverlayDelayCancellable(), cancelInFlight: true)

        case .cancelHideOverlayAnimationDelay:
            return .cancel(id: HidePlayerOverlayDelayCancellable())

        case .saveEpisodeProgress(let episodeId):
            guard let episodeId = episodeId, let episode = state.episodes.value?[id: episodeId] else { break }
            guard state.playerDuration > 0 else { break }
            guard var animeStore = state.animeStore.value else { break }

            let progress = state.playerProgress

            animeStore.updateProgress(
                for: episode,
                anime: state.anime,
                progress: progress
            )

            return .fireAndForget { [animeStore] in
                _ = try await repositoryClient.insertOrUpdate(animeStore)
            }

        case .closeSidebarAndShowControls:
            state.selectedSidebar = nil
            return .task { .showPlayerOverlay(true) }

        case .close:
            break
            
        case .setSidebar(let route):
            state.selectedSidebar = route

            if route != nil {
                return .merge(
                    .task { .cancelHideOverlayAnimationDelay },
                    .task { .showPlayerOverlay(false) }
                )
            }

        // Section actions

        case .sidebarSettingsSection(let section):
            if case .settings = state.selectedSidebar {
                state.selectedSidebar = .settings(.init(selectedSection: section))
            }

        // Fetched Anime Store

        case .fetchedAnimeInfoStore(let animeStores):
            state.animeStore = .success(.findOrCreate(state.anime, animeStores))

        // Fetch Episodes

        case .fetchEpisodes:
            guard !state.episodes.hasInitialized else {
                if state.episode != nil {
                    let selectedEpisode = state.selectedEpisode
                    return .task { .selectEpisode(selectedEpisode, saveProgress: false) }
                }
                break
            }
            state.episodes = .loading

            let animeId = state.anime.id

            return .task { [animeId] in
                .fetchedEpisodes(
                    try await animeClient.getEpisodes(animeId)
                )
            }
            .cancellable(id: FetchEpisodesCancellable())

        case .fetchedEpisodes(let episodes):
            state.episodes = .success(episodes.map({ $0.asRepresentable() }))
            let selectedEpisodeId = state.selectedEpisode
            return .task { .selectEpisode(selectedEpisodeId, saveProgress: false) }

        // Fetch Sources

        case .fetchSources:
            guard let provider = state.provider else { break }

            state.sources = .loading

            return .task { [provider] in
                await .fetchedSources(
                    .init { try await animeClient.getSources(provider) }
                )
            }
            .cancellable(id: FetchSourcesCancellable(), cancelInFlight: true)

        case .fetchedSources(.success(let sources)):
            let sources = Array(sources.sorted(by: \.quality).reversed())
            state.sources = .success(sources)
            // TODO: Set quality based on user defaults or the first one based on the one received

            let sourceId = sources.first?.id
            return .task { [sourceId] in .selectSource(sourceId, saveProgress: false) }

        case .fetchedSources(.failure):
            state.sources = .failed
            state.selectedSource = nil

        // Fetch Skip Times

        case .fetchSkipTimes:
            guard let episode = state.episode, let malId = state.anime.malId else {
                return .task { .fetchedSkipTimes(.success([])) }
            }

            state.skipTimes = .loading

            let episodeNumber = episode.number
            return .task { [malId, episodeNumber] in
                await .fetchedSkipTimes(
                    .init { try await animeClient.getSkipTimes(malId, episodeNumber) }
                )
            }
            .cancellable(id: FetchSkipTimesCancellable(), cancelInFlight: true)

        case .fetchedSkipTimes(.success(let skipTimes)):
            state.skipTimes = .success(skipTimes)

        case .fetchedSkipTimes(.failure):
            state.skipTimes = .success([])

        // Video Player Actions

        case .play:
            state.playerAction = .play

        case .togglePictureInPicture:
            if state.playerPiPStatus == .didStart {
                state.playerAction = .pictureInPicture(enable: false)
            } else {
                state.playerAction = .pictureInPicture(enable: true)
            }

        case .backwardsTapped:
            guard state.playerDuration > 0.0 else { break }
            let progress = state.playerProgress - 15 / state.playerDuration

            let requestedTime = max(progress, .zero)
            state.playerAction = .seekTo(requestedTime)

        case .forwardsTapped:
            guard state.playerDuration > 0.0 else { break }
            let progress = state.playerProgress + 15 / state.playerDuration

            let requestedTime = min(progress, 1.0)
            state.playerAction = .seekTo(requestedTime)

        // Internal Video Player Logic

        case .replayTapped:
            state.playerProgress = .zero
            state.playerAction = .play

        case .togglePlayback:
            if case .playing = state.status {
                state.playerAction = .pause
            } else {
                state.playerAction = .play
            }

        case .startSeeking:
            state.playerAction = .pause

        case .stopSeeking:
            state.playerAction = .seekTo(state.playerProgress)
            return .run { send in
                try? await mainQueue.sleep(for: 0.5)
                await send(.play)
            }

        case .seeking(to: let to):
            state.playerProgress = to

        case .volume(to: let volume):
            struct PlayerVolumeDebounceId: Hashable {}

            state.playerVolume = volume
            return .action(.playerAction(.volume(state.playerVolume)))
                .debounce(id: PlayerVolumeDebounceId(), for: 0.5, scheduler: mainQueue)

        // Player Actions Observer

        case .playerAction(let action):
            state.playerAction = action

        case .playerStatus(let status):
            guard status != state.playerStatus else { break }
            state.playerStatus = status

            if case .playing = status, state.showPlayerOverlay {
                return .task { .hideOverlayAnimationDelay }
            } else if state.showPlayerOverlay {
                return .task { .cancelHideOverlayAnimationDelay }
            }

        case .playerProgress(let progress):
            guard progress != state.playerProgress else { break }
            state.playerProgress = progress

        case .playerDuration(let duration):

            // First time duration is set and is not zero, resume progress

            if state.playerDuration == .zero && duration != .zero,
               let animeInfo = state.animeStore.value,
               let episode = state.episode,
               let savedEpisodeProgress = animeInfo.episodeStores.first(where: { $0.number ==  episode.number }),
               !savedEpisodeProgress.almostFinished {
                state.playerAction = .seekTo(savedEpisodeProgress.progress)
                state.playerProgress = savedEpisodeProgress.progress
            } else {
                state.playerAction = .seekTo(.zero)
                state.playerProgress = 0
            }

            state.playerDuration = duration

        case .playerBuffer(let buffer):
            state.playerBuffered = buffer

        case .playerPiPStatus(let status):
            state.playerPiPStatus = status

        case .playerPlayedToEnd:
            break

        case .playerVolume(let volume):
            state.playerVolume = volume

//        case .selectSubtitle(let subtitle):
//            break
//            state.playerSelectedSubtitle = subtitle

//        case .playerSubtitles(let subtitles):
//            break
//            state.playerSubtitles = subtitles

//        case .playerSelectedSubtitle(let subtitle):
//            break
//            state.playerSelectedSubtitle = subtitle

        case .stopAndClearPlayer:
            state.playerAction = .pause
            state.playerStatus = .idle
            state.playerProgress = .zero
            state.playerBuffered = .zero
            state.playerDuration = .zero
            state.playerPiPStatus = .restoreUI
            state.playerVolume = .zero
//            state.playerSubtitles = nil
//            state.playerSelectedSubtitle = nil

        case .binding:
            break
        }

        return .none
    }
}
