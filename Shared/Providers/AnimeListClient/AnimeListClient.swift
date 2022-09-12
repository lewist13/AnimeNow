//
//  AnimeListClient.swift
//  Anime Now!
//
//  Created by Erik Bautista on 9/3/22.
//

import ComposableArchitecture

struct AnimeListClient {
    let authenticate: () -> Effect<Void, API.Error>
    let topTrendingAnime: () -> Effect<[Anime], API.Error>
    let topUpcomingAnime: () -> Effect<[Anime], API.Error>
    let topAiringAnime: () -> Effect<[Anime], API.Error>
    let highestRatedAnime: () -> Effect<[Anime], API.Error>
    let mostPopularAnime: () -> Effect<[Anime], API.Error>
    let episodes: (_ animeId: Anime.ID) -> Effect<[Episode], API.Error>
}

extension AnimeListClient {
    enum AnimeLists: String, CaseIterable {
        case kitsu
        case enime
        case mock

        var getClient: AnimeListClient {
            switch self {
            case .kitsu:
                return .kitsu
            case .enime:
                return .mock
            case .mock:
                return .mock
            }
        }
    }
}
