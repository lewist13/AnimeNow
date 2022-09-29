//
//  AnimeClient.swift
//  Anime Now!
//
//  Created by Erik Bautista on 9/12/22.
//

import Foundation
import ComposableArchitecture

struct AnimeClient {
//    let setListClient: (List) -> Effect<Never, Never>
//    let setSourceClient: (DataSource) -> Effect<Never, Never>
    let getTopTrendingAnime: () -> Effect<[Anime], API.Error>
    let getTopUpcomingAnime: () -> Effect<[Anime], API.Error>
    let getTopAiringAnime: () -> Effect<[Anime], API.Error>
    let getHighestRatedAnime: () -> Effect<[Anime], API.Error>
    let getMostPopularAnime: () -> Effect<[Anime], API.Error>
    let searchAnimes: (String) -> Effect<[Anime], API.Error>
    let getEpisodes: (Anime.ID) -> Effect<[Episode], API.Error>
    let getSources: (Episode.ID) -> Effect<[Source], API.Error>
}
