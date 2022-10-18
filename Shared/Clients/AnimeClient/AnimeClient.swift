//
//  AnimeClient.swift
//  Anime Now!
//
//  Created by ErrorErrorError on 9/12/22.
//

import Foundation
import ComposableArchitecture

struct AnimeClient {
    let getTopTrendingAnime: () -> Effect<[Anime], EquatableError>
    let getTopUpcomingAnime: () -> Effect<[Anime], EquatableError>
    let getTopAiringAnime: () -> Effect<[Anime], EquatableError>
    let getHighestRatedAnime: () -> Effect<[Anime], EquatableError>
    let getMostPopularAnime: () -> Effect<[Anime], EquatableError>
    let getAnimes: ([Anime.ID]) -> Effect<[Anime], EquatableError>
    let getAnime: (Anime.ID) -> Effect<Anime, EquatableError>
    let searchAnimes: (String) -> Effect<[Anime], EquatableError>
    let getEpisodes: (Anime.ID) -> Effect<[Episode], Never>
    let getSources: (Episode.Provider) -> Effect<[Source], EquatableError>
    let getSkipTimes: (Int, Int) -> Effect<[SkipTime], EquatableError>
}
