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
                .map { $0?.data.Page.media ?? [] }
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
                .tryMap { object -> AniListAPI.Media in
                    if let object = object {
                        return object.data.Media
                    } else {
                        throw API.Error.parsingFailed("Failed to parse media object.")
                    }
                }
                .map(AniListAPI.convert(from:))
                .mapError { $0 as? API.Error ?? .badServerResponse("Unable to retrieve media object.") }
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
            if let episodes = episodesCache.value(forKey: animeId) {
                return .init(value: episodes)
            }
            return API.request(
                consumetApi,
                .anilist(.episodes(animeId: animeId, options: .init())),
                [ConsumetAPI.Episode].self
            )
                .tryCompactMap { episodes -> [ConsumetAPI.Episode] in
                    guard let episodes = episodes else {
                        throw API.Error.badServerResponse("Failed to retrieve episodes.")
                    }
                    return episodes
                }
                .map(ConsumetAPI.convert(from:))
                .mapError { $0 as? API.Error ?? .badServerResponse("Failed to retrieve episodes.") }
                .map { episodes -> [Episode] in
                    episodesCache.insert(episodes, forKey: animeId)
                    return episodes
                }
                .eraseToEffect()
        } getSources: { episodeId in
            // The episode id is always coming from gogoanime, so we will try to retrieve all different sources, and with dub and sub

            let gogoanimeSources = ConsumetAPI.Endpoint.anilist(
                .streamingLinks(
                    episodeId: episodeId,
                    provider: .gogoanime
                )
            )

            return API.request(consumetApi, gogoanimeSources, ConsumetAPI.StreamingLinksPayload.self)
                .map { $0?.sources ?? [] }
                .map { ConsumetAPI.convert(from: $0, provider: .gogoanime) }
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

