//
//  AnimeClient.swift
//  Anime Now!
//
//  Created by Erik Bautista on 9/12/22.
//

import Foundation
import ComposableArchitecture

struct AnimeClient {
    let setListClient: (List) -> Effect<Never, Never>
    let setSourceClient: (Source) -> Effect<Never, Never>
    let getTopTrendingAnime: () -> Effect<[Anime], API.Error>
    let getTopUpcomingAnime: () -> Effect<[Anime], API.Error>
    let getTopAiringAnime: () -> Effect<[Anime], API.Error>
    let getHighestRatedAnime: () -> Effect<[Anime], API.Error>
    let getMostPopularAnime: () -> Effect<[Anime], API.Error>
    let searchAnimes: (String) -> Effect<[Anime], API.Error>
    let getEpisodes: (Anime.ID) -> Effect<[Episode], API.Error>
    let getSources: (Episode.ID) -> Effect<[EpisodeSource], API.Error>
}

extension AnimeClient {
    enum List: String, CaseIterable {
        case kitsu
        case anilist

        var provider: ListClient {
            switch self {
            case .kitsu:
                return .kitsu
            case .anilist:
                return .anilist
            }
        }

        var canAccessWithoutAuth: Bool {
            switch self {
            case .kitsu, .anilist:
                return true
            }
        }
    }

    enum Source: String, CaseIterable {
        case live
        case mock

        var provider: SourceClient {
            switch self {
            case .live:
                return .live
            case .mock:
                return .mock
            }
        }
    }
}
