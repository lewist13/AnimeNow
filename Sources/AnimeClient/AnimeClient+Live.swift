//
//  AnimeClient+Live.swift
//  Anime Now!
//
//  Created by ErrorErrorError on 9/12/22.
//

import Combine
import APIClient
import Utilities
import Foundation
import SharedModels
import SociableWeaver
import ComposableArchitecture

extension AnimeClient {
    public static let liveValue: AnimeClient = {
        @Dependency(\.apiClient) var apiClient

        let cachedStreamingProviders = Cache<String, AnimeStreamingProvider>()

        return Self {
            let response = try await apiClient.request(
                .aniListAPI,
                .graphql(
                    AniListAPI.PageMediaQuery.self,
                    .init(
                        itemArguments: .defaultArgs + [.sort([.TRENDING_DESC, .POPULARITY_DESC])]
                    )
                )
            )
            return response.data.Page.items
                .map(AniListAPI.convert(from:))
        } getTopUpcomingAnime: {
            let response = try await apiClient.request(
                .aniListAPI,
                .graphql(
                    AniListAPI.PageMediaQuery.self,
                    .init(
                        itemArguments: .defaultArgs + [.sort([.TRENDING_DESC, .POPULARITY_DESC]), .status(.NOT_YET_RELEASED)]
                    )
                )
            )
            return response.data.Page.items
                .map(AniListAPI.convert(from:))
        } getTopAiringAnime: {
            let response = try await apiClient.request(
                .aniListAPI,
                .graphql(
                    AniListAPI.PageMediaQuery.self,
                    .init(
                        itemArguments: .defaultArgs + [.sort([.TRENDING_DESC, .SCORE_DESC]), .status(.RELEASING)]
                    )
                )
            )
            return response.data.Page.items
                .map(AniListAPI.convert(from:))
        } getHighestRatedAnime: {
            let response = try await apiClient.request(
                .aniListAPI,
                .graphql(
                    AniListAPI.PageMediaQuery.self,
                    .init(
                        itemArguments: .defaultArgs + [.sort([.SCORE_DESC]), .status(.RELEASING) ]
                    )
                )
            )
            return response.data.Page.items
                .map(AniListAPI.convert(from:))
        } getMostPopularAnime: {
            let response = try await apiClient.request(
                .aniListAPI,
                .graphql(
                    AniListAPI.PageMediaQuery.self,
                    .init(
                        itemArguments: .defaultArgs + [.sort([.POPULARITY_DESC])]
                    )
                )
            )
            return response.data.Page.items
                .map(AniListAPI.convert(from:))
        } getAnimes: { animeIds in
            let response = try await apiClient.request(
                .aniListAPI,
                .graphql(
                    AniListAPI.PageMediaQuery.self,
                    .init(
                        itemArguments: .defaultArgs + [.idIn(animeIds)]
                    )
                )
            )
            return response.data.Page.items
                .map(AniListAPI.convert(from:))
        } getAnime: { animeId in
            let response = try await apiClient.request(
                .aniListAPI,
                .graphql(
                    AniListAPI.Media.self,
                    [.id(animeId)]
                )
            )
            return AniListAPI.convert(from: response.data.Media)
        } searchAnimes: { query in
            let response = try await apiClient.request(
                .aniListAPI,
                .graphql(
                    AniListAPI.PageMediaQuery.self,
                    .init(
                        itemArguments: .defaultArgs + [.search(query), .sort([.POPULARITY_DESC])]
                    )
                )
            )
            return response.data.Page.items
                .map(AniListAPI.convert(from:))
        } getRecentlyUpdated: {
            let updated = try await apiClient.request(.enimeAPI, .recentEpisodes())
            return updated.data.map(EnimeAPI.convert)
        } getEpisodes: { animeId, provider in
            if let episodesCached = cachedStreamingProviders.value(forKey: "\(animeId)-\(provider.name)") {
                return episodesCached
            }

            async let sub = try? await apiClient.request(
                .consumetAPI,
                .anilistEpisodes(
                    animeId: animeId,
                    dub: false,
                    provider: provider.name
                )
            )

            async let dub = try? await apiClient.request(
                .consumetAPI,
                .anilistEpisodes(
                    animeId: animeId,
                    dub: true,
                    provider: provider.name
                )
            )

            var providerData = AnimeStreamingProvider(
                name: provider.name,
                logo: provider.logo,
                episodes: mergeSources(
                    await sub ?? .init(),
                    await dub ?? .init()
                )
            )

            cachedStreamingProviders.update(providerData, forKey: "\(animeId)-\(provider.name)")

            return providerData
        } getSources: { provider, link in
            switch link {
            case .stream(let id, let audio):
                let response = try await apiClient.request(
                    .consumetAPI,
                    .anilistWatch(
                        episodeId: id,
                        dub: audio.isDub,
                        provider: provider
                    )
                )

                return ConsumetAPI.convert(from: response)
            case .offline(let url):
                return .init([
                    .init(
                        url: url,
                        quality: .auto
                    )
                ])
            }
        } getSkipTimes: { malId, episodeNumber in
            let response = try await apiClient.request(
                .aniSkipAPI,
                .skipTime(
                    malId: malId,
                    episode: episodeNumber
                )
            )
            return AniSkipAPI.convert(from: response.results)
        } getAnimeProviders: {
            try await apiClient.request(
                .consumetAPI,
                .listProviders(of: .ANIME)
            )
        }
    }()
}

extension AnimeClient {
    fileprivate static func mergeSources(
        _ sub: [ConsumetAPI.Episode],
        _ dub: [ConsumetAPI.Episode]
    ) -> [Episode] {
        var episodes = [Episode]()

        let primary = sub
        let secondary = dub

        var primaryIndex = 0
        var secondaryIndex = 0

        let maxEpisodesCount = max(primary.count, secondary.count)

        for mainInx in 0..<maxEpisodesCount {
            let episodeNumber = mainInx + 1
            var providers = Set<EpisodeLink>()

            var mainEpisodeInfo: ConsumetAPI.Episode?

            if primaryIndex < primary.count {
                let episode = primary[primaryIndex]
                if episode.number == episodeNumber {
                    mainEpisodeInfo = episode
                    providers.insert(.stream(id: episode.id, audio: .sub))
                    primaryIndex += 1
                }
            }

            if secondaryIndex < secondary.count {
                let episode = secondary[secondaryIndex]
                if episode.number == episodeNumber {
                    mainEpisodeInfo = mainEpisodeInfo ?? episode
                    if let type = episode.type {
                        providers.insert(.stream(id: episode.id, audio: .custom(type)))
                    } else {
                        providers.insert(.stream(id: episode.id, audio: .dub))
                    }
                    secondaryIndex += 1
                }
            }

            guard let mainEpisodeInfo = mainEpisodeInfo else { continue }

            var episode = ConsumetAPI.convert(from: mainEpisodeInfo)
            episode.links = providers
            episodes.append(episode)
        }

        return episodes
    }
}
