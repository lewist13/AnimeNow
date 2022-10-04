//
//  AnimeClient+Live.swift
//  Anime Now!
//
//  Created by Erik Bautista on 9/12/22.
//

import Foundation
import URLRouting
import SociableWeaver
import ComposableArchitecture
import Combine

extension AnimeClient {
    static let live: AnimeClient = {
        let episodesCache = Cache<Anime.ID, [Episode]>()

        let aniListApi = AniListAPI()
        let consumetApi = ConsumetAPI()

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

            let response = API.request(
                aniListApi,
                endpoint,
                GraphQL.Response<AniListAPI.PageResponse<AniListAPI.MediaPage>>.self
            )
            return response
                .map(\.data.Page.media)
                .map(AniListAPI.convert(from:))
                .eraseToEffect()
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

            let response = API.request(
                aniListApi,
                endpoint,
                GraphQL.Response<AniListAPI.PageResponse<AniListAPI.MediaPage>>.self
            )
            return response
                .map(\.data.Page.media)
                .map(AniListAPI.convert(from:))
                .eraseToEffect()
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

            let response = API.request(
                aniListApi,
                endpoint,
                GraphQL.Response<AniListAPI.PageResponse<AniListAPI.MediaPage>>.self
            )
            return response
                .map(\.data.Page.media)
                .map(AniListAPI.convert(from:))
                .eraseToEffect()
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

            let response = API.request(
                aniListApi,
                endpoint,
                GraphQL.Response<AniListAPI.PageResponse<AniListAPI.MediaPage>>.self
            )
            return response
                .map(\.data.Page.media)
                .map(AniListAPI.convert(from:))
                .eraseToEffect()
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

            let response = API.request(
                aniListApi,
                endpoint,
                GraphQL.Response<AniListAPI.PageResponse<AniListAPI.MediaPage>>.self
            )
            return response
                .map(\.data.Page.media)
                .map(AniListAPI.convert(from:))
                .eraseToEffect()
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

            let response = API.request(
                aniListApi,
                endpoint,
                GraphQL.Response<AniListAPI.PageResponse<AniListAPI.MediaPage>>.self
            )
            return response
                .map(\.data.Page.media)
                .map(AniListAPI.convert(from:))
                .eraseToEffect()
        } getAnime: { animeId in
            let query = AniListAPI.Media.createQuery([.id(animeId)])
                .format()
            let endpoint = AniListAPI.Endpoint.graphql(
                .init(
                    query: query
                )
            )

            let response = API.request(
                aniListApi,
                endpoint,
                GraphQL.Response<AniListAPI.MediaResponses>.self
            )

            return response
                .map(\.data.Media)
                .map(AniListAPI.convert(from:))
                .eraseToEffect()
        } searchAnimes: { query in
            let query = AniListAPI.MediaPage.createQuery(
                AniListAPI.MediaPage.ArgumentOptions.defaults,
                AniListAPI.Media.ArgumentOptions.defaults + [.search(query)]
            )
                .format()
            let endpoint = AniListAPI.Endpoint.graphql(
                .init(
                    query: query
                )
            )

            let response = API.request(
                aniListApi,
                endpoint,
                GraphQL.Response<AniListAPI.PageResponse<AniListAPI.MediaPage>>.self
            )
            return response
                .map(\.data.Page.media)
                .map(AniListAPI.convert(from:))
                .eraseToEffect()
        } getEpisodes: { animeId in
            if let episodes = episodesCache.value(forKey: animeId) {
                return .init(value: episodes)
            }

            let gogoanimeSubEpisodes = API.request(
                consumetApi,
                .anilist(.episodes(animeId: animeId, options: .init())),
                [ConsumetAPI.Episode].self
            )

            let gogoanimeDubEpisodes = API.request(
                consumetApi,
                .anilist(
                    .episodes(
                        animeId: animeId,
                        options: .init(
                            dub: true
                        )
                    )
                ),
                [ConsumetAPI.Episode].self
            )

            let zoroEpisodes = API.request(
                consumetApi,
                .anilist(
                    .episodes(
                        animeId: animeId,
                        options: .init(
                            dub: false,
                            provider: .zoro
                        )
                    )
                ),
                [ConsumetAPI.Episode].self
            )

            let mergedSources = Publishers.Zip3(
                gogoanimeSubEpisodes.replaceError(with: []),
                gogoanimeDubEpisodes.replaceError(with: []),
                zoroEpisodes.replaceError(with: [])
            )
                .map(AnimeClient.mergeSources)

            return mergedSources
                .map { episodesCache.insert($0, forKey: animeId); return $0 }
                .eraseToAnyPublisher()
                .eraseToEffect()
        } getSources: { provider in

            let consumetProvider: ConsumetAPI.Endpoint.AnilistEndpoint.Provider

            if case .gogoanime = provider {
                consumetProvider = .gogoanime
            } else {
                consumetProvider = .zoro
            }

            let sourcesPublisher = ConsumetAPI.Endpoint.anilist(
                .watch(
                    episodeId: provider.id,
                    options: .init(
                        dub: provider.dub ?? false,
                        provider: consumetProvider
                    )
                )
            )

            return API.request(consumetApi, sourcesPublisher, ConsumetAPI.StreamingLinksPayload.self)
                .map(\.sources)
                .map(ConsumetAPI.convert(from:))
                .eraseToEffect()
        }
    }()
}

extension AnimeClient {
    fileprivate static func mergeSources(_ gogoSub: [ConsumetAPI.Episode], _ gogoDub: [ConsumetAPI.Episode], _ zoro: [ConsumetAPI.Episode]) -> [Episode] {
        var episodes = [Episode]()

        // TODO: Merge Zoro info

        let primary = gogoDub.count > gogoSub.count ? gogoDub : gogoSub
        let secondary = primary == gogoSub ? gogoDub : gogoSub
        let primaryDub = primary == gogoDub
        
        var primaryIndex = 0
        var secondaryIndex = 0
        
        for mainInx in 0..<(primary.last?.number ?? primary.count) {
            let episodeNumber = mainInx + 1
            var providers = [Episode.Provider]()
            
            var mainEpisodeInfo: ConsumetAPI.Episode?
            
            if primaryIndex < primary.count {
                let episode = primary[primaryIndex]
                if episode.number == episodeNumber {
                    mainEpisodeInfo = episode
                    providers.append(.gogoanime(id: episode.id, dub: primaryDub))
                    primaryIndex += 1
                }
            }
            
            if secondaryIndex < secondary.count {
                let episode = secondary[secondaryIndex]
                if episode.number == episodeNumber {
                    mainEpisodeInfo = mainEpisodeInfo ?? episode
                    providers.append(.gogoanime(id: episode.id, dub: !primaryDub))
                    secondaryIndex += 1
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

