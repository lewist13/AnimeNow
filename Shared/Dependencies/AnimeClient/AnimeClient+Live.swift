//
//  AnimeClient+Live.swift
//  Anime Now!
//
//  Created by ErrorErrorError on 9/12/22.
//

import Foundation
import URLRouting
import SociableWeaver
import ComposableArchitecture
import Combine

extension AnimeClient {
    static let liveValue: AnimeClient = {
        let episodesCache = Cache<Anime.ID, [Episode]>()

        let aniListApi = AniListAPI()
        let consumetApi = ConsumetAPI()
        let aniskipApi = AniSkipAPI()

        return Self {
            let query = AniListAPI.MediaPage.createQuery(
                AniListAPI.MediaPage.ArgumentOptions.defaults,
                AniListAPI.Media.ArgumentOptions.defaults + [.sort([.TRENDING_DESC, .POPULARITY_DESC])]
            )
                .format()
            let endpoint = AniListAPI.Endpoint.graphql(
                .init(
                    query: query
                )
            )

            let response = try await API.request(
                aniListApi,
                endpoint,
                GraphQL.Response<AniListAPI.PageResponse<AniListAPI.MediaPage>>.self
            )

            return response.data.Page.media
                .map(AniListAPI.convert(from:))

        } getTopUpcomingAnime: {
            let query = AniListAPI.MediaPage.createQuery(
                AniListAPI.MediaPage.ArgumentOptions.defaults,
                AniListAPI.Media.ArgumentOptions.defaults + [.sort([.TRENDING_DESC, .POPULARITY_DESC]), .status(.NOT_YET_RELEASED)]
            )
                .format()
            let endpoint = AniListAPI.Endpoint.graphql(
                .init(
                    query: query
                )
            )

            let response = try await API.request(
                aniListApi,
                endpoint,
                GraphQL.Response<AniListAPI.PageResponse<AniListAPI.MediaPage>>.self
            )

            return response.data.Page.media
                .map(AniListAPI.convert(from:))

        } getTopAiringAnime: {
            let query = AniListAPI.MediaPage.createQuery(
                AniListAPI.MediaPage.ArgumentOptions.defaults,
                AniListAPI.Media.ArgumentOptions.defaults + [.sort([.TRENDING_DESC, .SCORE_DESC]), .status(.RELEASING) ]
            )
                .format()
            let endpoint = AniListAPI.Endpoint.graphql(
                .init(
                    query: query
                )
            )

            let response = try await API.request(
                aniListApi,
                endpoint,
                GraphQL.Response<AniListAPI.PageResponse<AniListAPI.MediaPage>>.self
            )

            return response.data.Page.media
                .map(AniListAPI.convert(from:))

        } getHighestRatedAnime: {
            let query = AniListAPI.MediaPage.createQuery(
                AniListAPI.MediaPage.ArgumentOptions.defaults,
                AniListAPI.Media.ArgumentOptions.defaults + [.sort([.SCORE_DESC]), .status(.RELEASING) ]
            )
                .format()
            let endpoint = AniListAPI.Endpoint.graphql(
                .init(
                    query: query
                )
            )

            let response = try await API.request(
                aniListApi,
                endpoint,
                GraphQL.Response<AniListAPI.PageResponse<AniListAPI.MediaPage>>.self
            )

            return response.data.Page.media
                .map(AniListAPI.convert(from:))

        } getMostPopularAnime: {
            let query = AniListAPI.MediaPage.createQuery(
                AniListAPI.MediaPage.ArgumentOptions.defaults,
                AniListAPI.Media.ArgumentOptions.defaults + [.sort([.POPULARITY_DESC]) ]
            )
                .format()
            let endpoint = AniListAPI.Endpoint.graphql(
                .init(
                    query: query
                )
            )

            let response = try await API.request(
                aniListApi,
                endpoint,
                GraphQL.Response<AniListAPI.PageResponse<AniListAPI.MediaPage>>.self
            )

            return response.data.Page.media
                .map(AniListAPI.convert(from:))

        } getAnimes: { animeIds in
            let query = AniListAPI.MediaPage.createQuery(
                AniListAPI.MediaPage.ArgumentOptions.defaults,
                AniListAPI.Media.ArgumentOptions.defaults + [.idIn(animeIds)]
            )
                .format()
            let endpoint = AniListAPI.Endpoint.graphql(
                .init(
                    query: query
                )
            )

            let response = try await API.request(
                aniListApi,
                endpoint,
                GraphQL.Response<AniListAPI.PageResponse<AniListAPI.MediaPage>>.self
            )

            return response.data.Page.media
                .map(AniListAPI.convert(from:))

        } getAnime: { animeId in
            let query = AniListAPI.Media.createQuery([.id(animeId)])
                .format()
            let endpoint = AniListAPI.Endpoint.graphql(
                .init(
                    query: query
                )
            )

            let response = try await API.request(
                aniListApi,
                endpoint,
                GraphQL.Response<AniListAPI.MediaResponses>.self
            )

            return AniListAPI.convert(from: response.data.Media)

        } searchAnimes: { query in
            let query = AniListAPI.MediaPage.createQuery(
                AniListAPI.MediaPage.ArgumentOptions.defaults,
                AniListAPI.Media.ArgumentOptions.defaults + [.search(query), .sort([.POPULARITY_DESC])]
            )
                .format()
            let endpoint = AniListAPI.Endpoint.graphql(
                .init(
                    query: query
                )
            )

            let response = try await API.request(
                aniListApi,
                endpoint,
                GraphQL.Response<AniListAPI.PageResponse<AniListAPI.MediaPage>>.self
            )

            return response.data.Page.media
                .map(AniListAPI.convert(from:))

        } getEpisodes: { animeId in
            if let episodes = episodesCache.value(forKey: animeId) {
                return episodes
            }

            async let gogoSub = try? API.request(
                consumetApi,
                .anilist(
                    .episodes(
                        animeId: animeId,
                        options: .init(
                            fetchFiller: true
                        )
                    )
                ),
                [ConsumetAPI.Episode].self
            )

            async let gogoDub = try? API.request(
                consumetApi,
                .anilist(
                    .episodes(
                        animeId: animeId,
                        options: .init(
                            dub: true,
                            fetchFiller: true
                        )
                    )
                ),
                [ConsumetAPI.Episode].self
            )

            async let zoroSub = try? API.request(
                consumetApi,
                .anilist(
                    .episodes(
                        animeId: animeId,
                        options: .init(
                            dub: false,
                            provider: .zoro,
                            fetchFiller: true
                        )
                    )
                ),
                [ConsumetAPI.Episode].self
            )

            async let zoroDub = try? API.request(
                consumetApi,
                .anilist(
                    .episodes(
                        animeId: animeId,
                        options: .init(
                            dub: true,
                            provider: .zoro,
                            fetchFiller: true
                        )
                    )
                ),
                [ConsumetAPI.Episode].self
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
            let consumetProvider: ConsumetAPI.Endpoint.AnilistEndpoint.Provider

            if case .gogoanime = provider {
                consumetProvider = .gogoanime
            } else if case .zoro = provider {
                consumetProvider = .zoro
            } else if case .offline(let url) = provider {
                return .init([.init(id: 0, url: url, quality: .auto)])
            } else {
                throw ClientError.providerNotAvailable
            }

            guard let providerId = provider.id else {
                throw ClientError.providerInvalidId
            }

            let sourcesPublisher = ConsumetAPI.Endpoint.anilist(
                .watch(
                    episodeId: providerId,
                    options: .init(
                        dub: provider.dub ?? false,
                        provider: consumetProvider
                    )
                )
            )

            let response = try await API.request(
                consumetApi,
                sourcesPublisher,
                ConsumetAPI.StreamingLinksPayload.self
            )

            return ConsumetAPI.convert(from: response)

        } getSkipTimes: { malId, episodeNumber in
            let endpoint = AniSkipAPI.Endpoint.skipTime((malId, episodeNumber))
            let response = try await API.request(aniskipApi, endpoint, AniSkipAPI.Response.self)
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

extension String {
    public func trimHTMLTags() -> String? {
        guard let htmlStringData = self.data(using: String.Encoding.utf8) else {
            return nil
        }

        let options: [NSAttributedString.DocumentReadingOptionKey : Any] = [
            .documentType: NSAttributedString.DocumentType.html,
            .characterEncoding: String.Encoding.utf8.rawValue
        ]

        let attributedString = try? NSAttributedString(data: htmlStringData, options: options, documentAttributes: nil)
        return attributedString?.string
    }
}

