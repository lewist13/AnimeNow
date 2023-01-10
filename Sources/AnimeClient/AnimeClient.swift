//
//  AnimeClient.swift
//  Anime Now!
//
//  Created by ErrorErrorError on 9/12/22.
//

import Foundation
import SharedModels
import ComposableArchitecture

public struct AnimeClient {
    public let getTopTrendingAnime: @Sendable () async throws -> [Anime]
    public let getTopUpcomingAnime: @Sendable () async throws -> [Anime]
    public let getTopAiringAnime: @Sendable () async throws -> [Anime]
    public let getHighestRatedAnime: @Sendable () async throws -> [Anime]
    public let getMostPopularAnime: @Sendable () async throws -> [Anime]
    public let getAnimes: @Sendable ([Anime.ID]) async throws -> [Anime]
    public let getAnime: @Sendable (Anime.ID) async throws -> Anime
    public let searchAnimes: @Sendable (String) async throws -> [Anime]
    public let getEpisodes: @Sendable (Anime.ID, ProviderInfo) async -> AnimeStreamingProvider
    public let getSources: @Sendable (String, EpisodeLink) async throws -> SourcesOptions
    public let getSkipTimes: @Sendable (Int, Int) async throws -> [SkipTime]
    public let getAnimeProviders: @Sendable () async throws -> [ProviderInfo]
}

extension AnimeClient {
    enum Error: Swift.Error {
        case providerNotAvailable
        case providerInvalidId
    }
}

extension AnimeClient: DependencyKey {}

public extension DependencyValues {
    var animeClient: AnimeClient {
        get { self[AnimeClient.self] }
        set { self[AnimeClient.self] = newValue }
    }
}
