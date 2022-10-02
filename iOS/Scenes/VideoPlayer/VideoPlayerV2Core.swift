//
//  VideoPlayerV2Core.swift
//  Anime Now!
//
//  Created Erik Bautista on 10/1/22.
//  Copyright © 2022. All rights reserved.
//

import Foundation
import ComposableArchitecture

enum VideoPlayerV2Core {
    struct State: Equatable {
        var anime = LoadableState<Anime>.idle
        var episodes = LoadableState<IdentifiedArrayOf<Episode>>.idle
        var sources = LoadableState<[Source]>.idle
        var savedAnimeInfo = LoadableState<AnimeInfoStore>.idle

        var selectedEpisode: SelectedEpisodeIdentifier?
        var selectedSource: Source.ID?

        init(animeId: Anime.ID, selectedEpisode: SelectedEpisodeIdentifier) {
            self.selectedEpisode = selectedEpisode
        }

        enum SelectedEpisodeIdentifier: Equatable {
            case id(Episode.ID)
            case number(Int)
        }
    }

    enum Action: Equatable {

        // View Actions

        case onAppear
        case backwardsTapped
        case forwardTapped
        case playerTapped

        // Internal Actions

        case fetchAnime
        case fetchEpisodse
        case fetchSources
    }

    struct Environment {
        let animeClient: AnimeClient
        let mainQueue: AnySchedulerOf<DispatchQueue>
        let mainRunLoop: AnySchedulerOf<RunLoop>
        let repositoryClient: RepositoryClient
        let userDefaultsClient: UserDefaultsClient
    }
}

// MARK: Loading State

extension VideoPlayerV2Core.State {
    enum LoadingState {
        case fetchingAnime
        case fetchingEpisodes
        case fetchingSources
        case buffering
    }

    var loadingState: LoadingState? {
        if !anime.finished {
            return .fetchingAnime
        } else if !episodes.finished {
            return .fetchingEpisodes
        } else if !sources.finished {
            return .fetchingSources
        }
        return nil
    }
}

// MARK: Error State

extension VideoPlayerV2Core.State {
    enum Error {
        case failedToLoadAnime
        case failedToLoadEpisodes
        case failedToLoadSources
    }

    var error: Error? {
        if case .failed = anime {
            return .failedToLoadAnime
        } else if case .failed = episodes {
            return .failedToLoadEpisodes
        } else if case .failed = sources {
            return .failedToLoadSources
        }
        return nil
    }
}

extension VideoPlayerV2Core {
    static var reducer: Reducer<VideoPlayerV2Core.State, VideoPlayerV2Core.Action, VideoPlayerV2Core.Environment> {
        .init { state, action, environment in
            return .none
        }
    }
}
