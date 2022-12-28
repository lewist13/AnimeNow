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

        let episodesCache = Cache<Anime.ID, [Episode]>()

        let aniListApi = AniListAPI.shared
        let consumetApi = ConsumetAPI.shared
        let aniskipApi = AniSkipAPI.shared

        return Self {
            let response = try await apiClient.request(
                aniListApi,
                .graphql(
                    AniListAPI.PageQuery<AniListAPI.Media>.self,
                    .init(
                        itemArguments: .defaultArgs + [.sort([.TRENDING_DESC, .POPULARITY_DESC])]
                    )
                )
            )

            return response.data.Page.items
                .map(AniListAPI.convert(from:))
        } getTopUpcomingAnime: {
            let response = try await apiClient.request(
                aniListApi,
                .graphql(
                    AniListAPI.PageQuery<AniListAPI.Media>.self,
                    .init(
                        itemArguments: .defaultArgs + [.sort([.TRENDING_DESC, .POPULARITY_DESC]), .status(.NOT_YET_RELEASED)]
                    )
                )
            )

            return response.data.Page.items
                .map(AniListAPI.convert(from:))
        } getTopAiringAnime: {
            let response = try await apiClient.request(
                aniListApi,
                .graphql(
                    AniListAPI.PageQuery<AniListAPI.Media>.self,
                    .init(
                        itemArguments: .defaultArgs + [.sort([.TRENDING_DESC, .SCORE_DESC]), .status(.RELEASING)]
                    )
                )
            )

            return response.data.Page.items
                .map(AniListAPI.convert(from:))
        } getHighestRatedAnime: {
            let response = try await apiClient.request(
                aniListApi,
                .graphql(
                    AniListAPI.PageQuery<AniListAPI.Media>.self,
                    .init(
                        itemArguments: .defaultArgs + [.sort([.SCORE_DESC]), .status(.RELEASING) ]
                    )
                )
            )

            return response.data.Page.items
                .map(AniListAPI.convert(from:))
        } getMostPopularAnime: {
            let response = try await apiClient.request(
                aniListApi,
                .graphql(
                    AniListAPI.PageQuery<AniListAPI.Media>.self,
                    .init(
                        itemArguments: .defaultArgs + [.sort([.POPULARITY_DESC])]
                    )
                )
            )

            return response.data.Page.items
                .map(AniListAPI.convert(from:))
        } getAnimes: { animeIds in
            let response = try await apiClient.request(
                aniListApi,
                .graphql(
                    AniListAPI.PageQuery<AniListAPI.Media>.self,
                    .init(
                        itemArguments: .defaultArgs + [.idIn(animeIds)]
                    )
                )
            )

            return response.data.Page.items
                .map(AniListAPI.convert(from:))
        } getAnime: { animeId in
            let response = try await apiClient.request(
                aniListApi,
                .graphql(
                    AniListAPI.Media.self,
                    [.id(animeId)]
                )
            )

            return AniListAPI.convert(from: response.data.Media)
        } searchAnimes: { query in
            let response = try await apiClient.request(
                aniListApi,
                .graphql(
                    AniListAPI.PageQuery<AniListAPI.Media>.self,
                    .init(
                        itemArguments: .defaultArgs + [.search(query), .sort([.POPULARITY_DESC])]
                    )
                )
            )

            return response.data.Page.items
                .map(AniListAPI.convert(from:))
        } getEpisodes: { animeId in
            if let episodes = episodesCache.value(forKey: animeId) {
                return episodes
            }

            async let gogoSub = try? apiClient.request(
                consumetApi,
                .anilistEpisodes(
                    animeId: animeId,
                    dub: false,
                    provider: .gogoanime,
                    fetchFiller: true
                )
            )

            async let gogoDub = try? apiClient.request(
                consumetApi,
                .anilistEpisodes(
                    animeId: animeId,
                    dub: true,
                    provider: .gogoanime,
                    fetchFiller: true
                )
            )

            async let zoroSub = try? apiClient.request(
                consumetApi,
                .anilistEpisodes(
                    animeId: animeId,
                    dub: false,
                    provider: .zoro,
                    fetchFiller: true
                )
            )

            async let zoroDub = try? apiClient.request(
                consumetApi,
                .anilistEpisodes(
                    animeId: animeId,
                    dub: true,
                    provider: .zoro,
                    fetchFiller: true
                )
            )

            let episodes = await AnimeClient.mergeSources(
                gogoSub ?? [],
                gogoDub ?? [],
                zoroSub ?? [],
                zoroDub ?? []
            )

            if episodes.count > 0 {
                episodesCache.insert(episodes, forKey: animeId)
            }

            return episodes

        } getSources: { provider in
            let consumetProvider: ConsumetAPI.Provider

            if case .gogoanime = provider {
                consumetProvider = .gogoanime
            } else if case .zoro = provider {
                consumetProvider = .zoro
            } else if case .offline(let url) = provider {
                return .init([.init(id: 0, url: url, quality: .auto)])
            } else {
                throw Error.providerNotAvailable
            }

            guard let providerId = provider.id else {
                throw Error.providerInvalidId
            }

            let response = try await apiClient.request(
                consumetApi,
                .anilistWatch(
                    episodeId: providerId,
                    dub: provider.dub ?? false,
                    provider: consumetProvider
                )
            )

            return ConsumetAPI.convert(from: response)
        } getSkipTimes: { malId, episodeNumber in
            let response = try await apiClient.request(
                aniskipApi,
                .skipTime(
                    malId: malId,
                    episode: episodeNumber
                )
            )
            return AniSkipAPI.convert(from: response.results)
        }
    }()
}

extension AnimeClient {
    fileprivate static func mergeSources(
        _ gogoSub: [ConsumetAPI.Episode],
        _ gogoDub: [ConsumetAPI.Episode],
        _ zoroSub: [ConsumetAPI.Episode],
        _ zoroDub: [ConsumetAPI.Episode]
    ) -> [Episode] {
        var episodes = [Episode]()

        let primary = gogoSub
        let secondary = gogoDub
        let tertiary = zoroSub
        let quartery = zoroDub

        var primaryIndex = 0
        var secondaryIndex = 0
        var tertiaryIndex = 0
        var quarteryIndex = 0

        let maxEpisodesCount = max(primary.count, max(secondary.count, tertiary.count))

        for mainInx in 0..<maxEpisodesCount {
            let episodeNumber = mainInx + 1
            var providers = [Provider]()

            var mainEpisodeInfo: ConsumetAPI.Episode?

            if primaryIndex < primary.count {
                let episode = primary[primaryIndex]
                if episode.number == episodeNumber {
                    mainEpisodeInfo = episode
                    providers.append(.gogoanime(id: episode.id, dub: false))
                    primaryIndex += 1
                }
            }

            if secondaryIndex < secondary.count {
                let episode = secondary[secondaryIndex]
                if episode.number == episodeNumber {
                    mainEpisodeInfo = mainEpisodeInfo ?? episode
                    providers.append(.gogoanime(id: episode.id, dub: true))
                    secondaryIndex += 1
                }
            }

            if tertiaryIndex < tertiary.count {
                let episode = tertiary[tertiaryIndex]
                if episode.number == episodeNumber {
                    mainEpisodeInfo = mainEpisodeInfo ?? episode
                    providers.append(.zoro(id: episode.id, dub: false))
                    tertiaryIndex += 1
                }
            }

            if quarteryIndex < quartery.count {
                let episode = quartery[quarteryIndex]
                if episode.number == episodeNumber {
                    mainEpisodeInfo = mainEpisodeInfo ?? episode
                    providers.append(.zoro(id: episode.id, dub: true))
                    quarteryIndex += 1
                }
            }

            guard let mainEpisodeInfo = mainEpisodeInfo else { continue }

            var episode = ConsumetAPI.convert(from: mainEpisodeInfo)
            episode.providers = providers
            episodes.append(episode)
        }

        return episodes
    }
}
