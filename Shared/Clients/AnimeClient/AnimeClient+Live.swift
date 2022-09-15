//
//  AnimeClient+Live.swift
//  Anime Now!
//
//  Created by Erik Bautista on 9/12/22.
//

import Foundation


extension AnimeClient {
    static func live(list: List = .kitsu, source: Source = .live) -> AnimeClient {
        var selectedAnimeList = list
        var selectedSource = source

        return Self { list in
            .fireAndForget {
                selectedAnimeList = list
            }
        } setSourceClient: { source in
            .fireAndForget {
                selectedSource = source
            }
        } getTopTrendingAnime: {
            selectedAnimeList.provider
                .topTrendingAnime()
        } getTopUpcomingAnime: {
            selectedAnimeList.provider.topUpcomingAnime()
        } getTopAiringAnime: {
            selectedAnimeList.provider.topAiringAnime()
        } getHighestRatedAnime: {
            selectedAnimeList.provider.highestRatedAnime()
        } getMostPopularAnime: {
            selectedAnimeList.provider.mostPopularAnime()
        } searchAnimes: { query in
            selectedAnimeList.provider.search(query)
        } getEpisodes: { animeId in
            selectedSource.provider.episodes(animeId)
        }
    }
}
