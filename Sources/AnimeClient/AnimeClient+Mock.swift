//
//  AnimeClient+Mock.swift
//  Anime Now!
//
//  Created by ErrorErrorError on 9/12/22.
//

import ComposableArchitecture

extension AnimeClient {
    public static let previewValue = Self {
        []
    } getTopUpcomingAnime: {
        []
    } getTopAiringAnime: {
        []
    } getHighestRatedAnime: {
        []
    } getMostPopularAnime: {
        []
    } getAnimes: { _ in
        []
    } getAnime: { _ in
        throw AnimeClient.Error.providerNotAvailable
    } searchAnimes: { _ in
        []
    } getEpisodes: { _ in
        []
    } getSources: { _ in
        .init([], subtitles: [])
    } getSkipTimes: { _, _ in
        []
    }
}
