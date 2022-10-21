//
//  AnimeNowVideoPlayerCore.swift
//  Anime Now!
//
//  Created by ErrorErrorError on 10/1/22.
//  Copyright © 2022. All rights reserved.
//

import Foundation
import ComposableArchitecture
import AVFoundation
import SwiftUI

enum AnimeNowVideoPlayerCore {
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

        // Player

        @BindableState var playerAction: VideoPlayer.Action? = nil
        @BindableState var playerProgress = Double.zero
        var playerBuffered = Double.zero
        var playerDuration = Double.zero
        var playerStatus = VideoPlayer.Status.idle
        var playerPiPStatus = VideoPlayer.PIPStatus.restoreUI
//        var playerSubtitles: AVMediaSelectionGroup?

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

        // Internal Actions

        case initializeFirstTime
        case saveEpisodeProgress(AnyEpisodeRepresentable.ID?)
        case setSidebar(Sidebar?)
        case showPlayerOverlay(Bool)
        case closeSidebarAndShowControls
        case hideOverlayAnimationDelay
        case cancelHideOverlayAnimationDelay
        case close

        case fetchedAnimeInfoStore([AnimeStore])
        case fetchEpisodes
        case fetchedEpisodes([Episode])
        case fetchSources
        case fetchedSources(Result<[Source], EquatableError>)
        case fetchSkipTimes
        case fetchedSkipTimes(Result<[SkipTime], EquatableError>)

        // Sidebar Actions

        case sidebarSettingsSection(Sidebar.SettingsState.Section?)

        // Player Actions

        case backwardsTapped
        case forwardsTapped
        case replayTapped
        case togglePlayback
        case startSeeking
        case stopSeeking
        case seeking(to: Double)

        case playerStatus(VideoPlayer.Status)
        case playerDuration(Double)
        case playerBuffer(Double)
        case playerPiPStatus(VideoPlayer.PIPStatus)
        case playerPlayedToEnd
//        case playerSubtitles(AVMediaSelectionGroup?)
//        case playerSelectedSubtitle(AVMediaSelectionOption?)
        case stopAndClearPlayer

        // Internal Video Player Actions

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

// MARK: Status State

extension AnimeNowVideoPlayerCore.State {
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

extension AnimeNowVideoPlayerCore.State {
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

extension AnimeNowVideoPlayerCore.State {
    var almostEnding: Bool {
        playerProgress >= 0.9
    }

    var finishedWatching: Bool {
        playerProgress >= 1.0
    }
}

extension AnimeNowVideoPlayerCore.State {
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

extension AnimeNowVideoPlayerCore {
    static var reducer = Reducer<AnimeNowVideoPlayerCore.State, AnimeNowVideoPlayerCore.Action, AnimeNowVideoPlayerCore.Environment>
    { state, action, environment in
        struct HidePlayerOverlayDelayCancellable: Hashable {}
        struct FetchEpisodesCancellable: Hashable {}
        struct FetchSourcesCancellable: Hashable {}
        struct CancelAnimeStoreObservable: Hashable {}
        struct FetchSkipTimesCancellable: Hashable {}
        struct CancelAnimeFetchId: Hashable {}

        let overlayVisibilityAnimation = Animation.easeInOut(
            duration: 0.3
        )

        switch action {

        // View Actions

        case .onAppear:
            guard !state.hasInitialized else { break }
            return .init(value: .initializeFirstTime)

        case .playerTapped:
            guard state.selectedSidebar == nil else {
                return .init(value: .closeSidebar)
            }

            let showingOverlay = !state.showPlayerOverlay

            var effects: [Effect<Action, Never>] = [
                .init(value: .showPlayerOverlay(showingOverlay))
                    .receive(on: environment.mainQueue.animation(overlayVisibilityAnimation))
                    .eraseToEffect()
            ]

            if showingOverlay && state.playerStatus == .playing {
                // Show overlay with timeout if the video is currently playing
                effects.append(
                    .init(value: .hideOverlayAnimationDelay)
                )
            } else {
                effects.append(
                    .init(value: .cancelHideOverlayAnimationDelay)
                )
            }

            return .concatenate(effects)

        case .showEpisodesSidebar:
            return .init(value: .setSidebar(.episodes))
                .receive(on: environment.mainQueue.animation(.easeInOut(duration: 0.35)))
                .eraseToEffect()

        case .showSettingsSidebar:
            return .init(value: .setSidebar(.settings(.init())))
                .receive(on: environment.mainQueue.animation(.easeInOut(duration: 0.35)))
                .eraseToEffect()

        case .showSubtitlesSidebar:
            return .init(value: .setSidebar(.subtitles))
                .receive(on: environment.mainQueue.animation(.easeInOut(duration: 0.35)))
                .eraseToEffect()

        case .closeButtonTapped:
            return .concatenate(
                .init(value: .saveEpisodeProgress(state.episode?.id)),
                .cancel(id: CancelAnimeStoreObservable()),
                .cancel(id: CancelAnimeFetchId()),
                .cancel(id: FetchSourcesCancellable()),
                .cancel(id: FetchEpisodesCancellable()),
                .cancel(id: FetchSkipTimesCancellable()),
                .cancel(id: HidePlayerOverlayDelayCancellable()),
                .init(value: .close)
                .delay(for: 0.25, scheduler: environment.mainQueue)
                .eraseToEffect()
            )

        case .closeSidebar:
            return .init(value: .setSidebar(nil))
                .receive(on: environment.mainQueue.animation(.easeInOut(duration: 0.25)))
                .eraseToEffect()

        case .selectEpisode(let episodeId, let saveProgress):
            var effects = [Effect<Action, Never>]()

            // Before selecting episode, save progress

            if saveProgress {
                effects.append(.init(value: .saveEpisodeProgress(state.episode?.id)))
            }

            state.selectedEpisode = episodeId

            // TODO: Add user defaults for preferred provider or fallback to first
            let provider = state.episode?.providers.first?.id

            effects.append(.init(value: .stopAndClearPlayer))
            effects.append(.init(value: .selectProvider(provider, saveProgress: false)))
            effects.append(.init(value: .fetchSkipTimes))

            return .merge(effects)
            
        case .selectProvider(let providerId, let saveProgress):
            var effects = [Effect<Action, Never>]()

            // Before selecting provider, save progress

            if saveProgress {
                effects.append(.init(value: .saveEpisodeProgress(state.episode?.id)))
            }

            state.selectedProvider = providerId

            effects.append(.init(value: .stopAndClearPlayer))
            effects.append(.init(value: .fetchSources))

            return .merge(effects)

        case .selectSource(let sourceId, let saveProgress):
            var effects = [Effect<Action, Never>]()

            // Before selecting source, save progress

            if saveProgress {
                effects.append(.init(value: .saveEpisodeProgress(state.episode?.id)))
            }

            state.selectedSource = sourceId

            return .concatenate(effects)

        case .selectSidebarSettings(let section):
            return .init(value: .sidebarSettingsSection(section))
                .receive(on: environment.mainQueue.animation(.easeInOut(duration: 0.25)))
                .eraseToEffect()

        // Internal Actions
    
        case .initializeFirstTime:
            state.hasInitialized = true
            return .merge(
                .init(value: .fetchEpisodes),
                environment.repositoryClient.observe(
                    .init(
                        format: "id == %d",
                        state.anime.id
                    ),
                    []
                )
                .receive(on: environment.mainQueue)
                .eraseToEffect()
                .map(Action.fetchedAnimeInfoStore)
                .cancellable(id: CancelAnimeStoreObservable())
            )

        case .showPlayerOverlay(let show):
            state.showPlayerOverlay = show

        case .hideOverlayAnimationDelay:
            return .init(value: .showPlayerOverlay(false))
                .delay(
                    for: 5,
                    scheduler:  environment.mainQueue.animation(overlayVisibilityAnimation)
                )
                .eraseToEffect()
                .cancellable(id: HidePlayerOverlayDelayCancellable())

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

            return environment.repositoryClient.insertOrUpdate(animeStore)
                .receive(on: environment.mainQueue)
                .fireAndForget()

        case .closeSidebarAndShowControls:
            state.selectedSidebar = nil
            return .init(value: .showPlayerOverlay(true))

        case .close:
            break
            
        case .setSidebar(let route):
            state.selectedSidebar = route

            if route != nil {
                return .merge(
                    .init(value: .cancelHideOverlayAnimationDelay),
                    .init(value: .showPlayerOverlay(false))
                )
            }

        // Section actions

        case .sidebarSettingsSection(let section):
            if case .settings(var value) = state.selectedSidebar {
                state.selectedSidebar = .settings(.init(selectedSection: section))
            }

        // Fetched Anime Store

        case .fetchedAnimeInfoStore(let animeStores):
            state.animeStore = .success(.findOrCreate(state.anime, animeStores))

        // Fetch Episodes

        case .fetchEpisodes:
            guard !state.episodes.hasInitialized else {
                if state.episode != nil {
                    return .init(value: .selectEpisode(state.selectedEpisode, saveProgress: false))
                }
                break
            }
            state.episodes = .loading
            return environment.animeClient.getEpisodes(state.anime.id)
                .receive(on: environment.mainQueue)
                .eraseToEffect()
                .map(Action.fetchedEpisodes)
                .cancellable(id: FetchEpisodesCancellable())

        case .fetchedEpisodes(let episodes):
            state.episodes = .success(episodes.map({ $0.asRepresentable() }))
            return .init(value: .selectEpisode(state.selectedEpisode, saveProgress: false))

        // Fetch Sources

        case .fetchSources:
            guard let provider = state.provider else { break }

            state.sources = .loading
            return environment.animeClient.getSources(provider)
                .receive(on: environment.mainQueue)
                .catchToEffect()
                .map(Action.fetchedSources)
                .cancellable(id: FetchSourcesCancellable(), cancelInFlight: true)

        case .fetchedSources(.success(let sources)):
            let sources = Array(sources.sorted(by: \.quality).reversed())
            state.sources = .success(sources)
            // TODO: Set quality based on user defaults or the first one based on the one received
            return .init(value: .selectSource(sources.first?.id, saveProgress: false))

        case .fetchedSources(.failure):
            state.sources = .failed
            state.selectedSource = nil

        // Fetch Skip Times

        case .fetchSkipTimes:
            guard let episode = state.episode, let malId = state.anime.malId else {
                return .init(value: .fetchedSkipTimes(.success([])))
            }
            state.skipTimes = .loading
            return environment.animeClient.getSkipTimes(malId, episode.number)
                .receive(on: environment.mainQueue)
                .catchToEffect()
                .map(Action.fetchedSkipTimes)
                .cancellable(id: FetchSkipTimesCancellable(), cancelInFlight: true)

        case .fetchedSkipTimes(.success(let skipTimes)):
            state.skipTimes = .success(skipTimes)

        case .fetchedSkipTimes(.failure):
            state.skipTimes = .success([])

        // Video Player Actions

        case .backwardsTapped:
            guard state.playerDuration > 0.0 else { break }
            let progress = state.playerProgress - 15 / state.playerDuration

            let requestedTime = max(progress, .zero)
            return .merge(
                .init(value: .startSeeking),
                .init(value: .seeking(to: requestedTime)),
                .init(value: .stopSeeking)
            )

        case .forwardsTapped:
            guard state.playerDuration > 0.0 else { break }
            let progress = state.playerProgress + 15 / state.playerDuration

            let requestedTime = min(progress, 1.0)
            return .merge(
                .init(value: .startSeeking),
                .init(value: .seeking(to: requestedTime)),
                .init(value: .stopSeeking)
            )

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
            state.playerAction = .play

        case .seeking(to: let to):
            state.playerProgress = to

        case .playerStatus(let status):
            guard status != state.playerStatus else { break }
            state.playerStatus = status

            if case .playing = status, state.showPlayerOverlay {
                return .init(value: .hideOverlayAnimationDelay)
            } else if state.showPlayerOverlay {
                return .init(value: .cancelHideOverlayAnimationDelay)
            }

        case .playerDuration(let duration):

            // First time duration is set and is not zero, resume progress

            if state.playerDuration == .zero && duration != .zero,
               let animeInfo = state.animeStore.value,
               let episode = state.episode,
               let savedEpisodeProgress = animeInfo.episodeStores.first(where: { $0.number ==  episode.number }),
               !savedEpisodeProgress.almostFinished {
                state.playerProgress = savedEpisodeProgress.progress
            } else {
                state.playerProgress = .zero
            }

            state.playerDuration = duration

        case .playerBuffer(let buffer):
            state.playerBuffered = buffer

        case .playerPiPStatus(let status):
            state.playerPiPStatus = status

        case .playerPlayedToEnd:
            break

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
//            state.playerSubtitles = nil
//            state.playerSelectedSubtitle = nil

        case .binding:
            break
        }

        return .none
    }
    .binding()
}
