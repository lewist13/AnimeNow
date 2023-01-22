//
//  AnimeClient+Mock.swift
//  Anime Now!
//
//  Created by ErrorErrorError on 9/12/22.
//

import SharedModels
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
    } getRecentlyUpdated: {
        []
    } getEpisodes: { _,_  in
        .init(name: "", episodes: [Episode(title: "", number: 0, description: "", isFiller: true)])
    } getSources: { _,_ in
        .init([])
    } getSkipTimes: { _,_  in
            .init()
    } getAnimeProviders: {
        []
    }
}
