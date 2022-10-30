//
//  AnimeClient+Mock.swift
//  Anime Now!
//
//  Created by ErrorErrorError on 9/12/22.
//

import Foundation

extension AnimeClient {
    static let mock = Self {
        [.attackOnTitan, .narutoShippuden]
    } getTopUpcomingAnime: {
        [.attackOnTitan, .narutoShippuden]
    } getTopAiringAnime: {
        [.attackOnTitan, .narutoShippuden]
    } getHighestRatedAnime: {
        [.attackOnTitan, .narutoShippuden]
    } getMostPopularAnime: {
        [.attackOnTitan, .narutoShippuden]
    } getAnimes: { _ in
        [.attackOnTitan, .narutoShippuden]
    } getAnime: { _ in
        .narutoShippuden
    } searchAnimes: { _ in
        [.attackOnTitan, .narutoShippuden]
    } getEpisodes: { _ in
        []
    } getSources: { _ in
        .init([], subtitles: [])
    } getSkipTimes: { _, _ in
        []
    }
}
