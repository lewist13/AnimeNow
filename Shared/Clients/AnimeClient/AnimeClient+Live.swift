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


extension AnimeClient {
    static let live: AnimeClient = {
        let aniListApi = AniListAPI()
        let kitsuApi = KitsuAPI()
        let enimeApi = EnimeAPI()
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
                .map { $0?.data.Page.media ?? [] }
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
                .map { $0?.data.Page.media ?? [] }
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
                .map { $0?.data.Page.media ?? [] }
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
                .map { $0?.data.Page.media ?? [] }
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
                .map { $0?.data.Page.media ?? [] }
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
                .map { $0?.data.Page.media ?? [] }
                .map(AniListAPI.convert(from:))
                .eraseToEffect()
        } getEpisodes: { animeId in
            return API.request(
                consumetApi,
                .anilist(.animeInfo(animeId: animeId, options: .init())),
                ConsumetAPI.Anime.self
            )
                .tryCompactMap {
                    guard let anime = $0 else {
                        throw API.Error.badServerResponse("Failed to get anilist anime for episodes.")
                    }
                    return anime.episodes
                }
                .map(ConsumetAPI.convert(from:))
                .mapError { $0 as? API.Error ?? .badServerResponse("Failed to get anilist anime for episodes.") }
                .eraseToEffect()
        } getSources: { episodeId in
            // The episode id is always coming from gogoanime, so we will try to retrieve all different sources, and with dub and sub

            let endpoint = ConsumetAPI.Endpoint.anilist(
                .streamingLinks(
                    episodeId: episodeId,
                    provider: .gogoanime
                )
            )

            return API.request(consumetApi, endpoint, ConsumetAPI.StreamingLinksPayload.self)
                .map { $0?.sources ?? [] }
                .map(ConsumetAPI.convert(from:))
                .eraseToEffect()
        }
    }()
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

