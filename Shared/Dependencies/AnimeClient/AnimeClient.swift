//
//  AnimeClient.swift
//  Anime Now!
//
//  Created by ErrorErrorError on 9/12/22.
//

import Foundation
import ComposableArchitecture

struct AnimeClient {
    var getTopTrendingAnime: @Sendable () async throws -> [Anime]
    var getTopUpcomingAnime: @Sendable () async throws -> [Anime]
    var getTopAiringAnime: @Sendable () async throws -> [Anime]
    var getHighestRatedAnime: @Sendable () async throws -> [Anime]
    var getMostPopularAnime: @Sendable () async throws -> [Anime]
    var getAnimes: @Sendable ([Anime.ID]) async throws -> [Anime]
    var getAnime: @Sendable (Anime.ID) async throws -> Anime
    var searchAnimes: @Sendable (String) async throws -> [Anime]
    var getEpisodes: @Sendable (Anime.ID) async throws -> [Episode]
    var getSources: @Sendable (Provider) async throws -> SourcesOptions
    var getSkipTimes: @Sendable (Int, Int) async throws -> [SkipTime]
}

extension AnimeClient {
    enum Error: Swift.Error {
        case providerNotAvailable
        case providerInvalidId
    }
}

extension AnimeClient: DependencyKey {}

extension DependencyValues {
    var animeClient: AnimeClient {
        get { self[AnimeClient.self] }
        set { self[AnimeClient.self] = newValue }
    }
}
