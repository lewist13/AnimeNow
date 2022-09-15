//
//  AnimeClient+Mock.swift
//  Anime Now!
//
//  Created by Erik Bautista on 9/12/22.
//

import Foundation

extension AnimeClient {
    static let mock = Self { _ in
        .none
    } setSourceClient: { _ in
        .none
    } getTopTrendingAnime: {
        .none
    } getTopUpcomingAnime: {
        .none
    } getTopAiringAnime: {
        .none
    } getHighestRatedAnime: {
        .none
    } getMostPopularAnime: {
        .none
    } searchAnimes: { _ in
        .none
    } getEpisodes: { _ in
        .none
    }
}
