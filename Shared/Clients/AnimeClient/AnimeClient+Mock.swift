//
//  AnimeClient+Mock.swift
//  Anime Now!
//
//  Created by Erik Bautista on 9/12/22.
//

import Foundation

extension AnimeClient {
    static let mock = Self {
        .init(value: [.attackOnTitan, .narutoShippuden])
    } getTopUpcomingAnime: {
        .init(value: [])
    } getTopAiringAnime: {
        .init(value: [])
    } getHighestRatedAnime: {
        .init(value: [])
    } getMostPopularAnime: {
        .init(value: [])
    } getAnimes: { _ in
        .none
    } getAnime: { _ in
        .none
    } searchAnimes: { _ in
        .none
    } getEpisodes: { _ in
        .none
    } getSources: { _ in
        .none
    }
}
