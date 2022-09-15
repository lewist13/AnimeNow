//
//  ListClient.swift
//  Anime Now!
//
//  Created by Erik Bautista on 9/3/22.
//

import ComposableArchitecture

struct ListClient {
    let topTrendingAnime: () -> Effect<[Anime], API.Error>
    let topUpcomingAnime: () -> Effect<[Anime], API.Error>
    let topAiringAnime: () -> Effect<[Anime], API.Error>
    let highestRatedAnime: () -> Effect<[Anime], API.Error>
    let mostPopularAnime: () -> Effect<[Anime], API.Error>
    let search: (String) -> Effect<[Anime], API.Error>
}
