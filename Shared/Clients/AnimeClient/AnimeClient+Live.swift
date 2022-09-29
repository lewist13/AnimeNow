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
            let provider: EnimeAPI.Endpoint.ExternalProvider
            if case let .kitsu(kitsuId) = animeId {
                provider = .init(provider: .kitsu, id: kitsuId)
            } else if case let .anilist(anilistId) = animeId {
                provider = .init(provider: .anilist, id: anilistId)
            } else {
                provider = .init(provider: .mal, id: animeId.value)
            }

            let providerId: Effect<Int, API.Error>
            if provider.provider != .anilist {
                let mappingEndpoint = EnimeAPI.Endpoint.mapping(provider)
                let mappingResponse = API.request(enimeApi, mappingEndpoint, EnimeAPI.Anime.self)

                providerId = mappingResponse
                    .tryCompactMap { anime in
                        guard let anilistId = anime?.anilistId else {
                            throw API.Error.badServerResponse("Failed to get anime id mapping.")
                        }
                        return anilistId
                    }
                    .mapError { $0 as? API.Error ?? .badServerResponse("Failed to get anime id mapping.") }
                    .eraseToEffect()
            } else {
                providerId = .init(value: Int(provider.id) ?? 0)
                    .eraseToEffect()
            }

            return providerId
                .flatMap { id in
                    API.request(
                        consumetApi,
                        .anilist(.animeInfo(animeId: id, options: .init())),
                        ConsumetAPI.Anime.self
                    )
                }
                .tryCompactMap {
                    guard let anime = $0 else {
                        throw API.Error.badServerResponse("Failed to get anilist anime for episodes.")
                    }
                    return anime.episodes
                }
                .map(convertConsumetEpisodeToEpisode(episodes:))
                .mapError { $0 as? API.Error ?? .badServerResponse("Failed to get anilist anime for episodes.") }
                .eraseToEffect()
        } getSources: { episodeId in
                // The episode id is always coming from gogoanime, so we will try to retrieve all different sources, and with dub and sub

                let endpoint = ConsumetAPI.Endpoint.anilist(
                    .streamingLinks(
                        episodeId: episodeId,
                        provider: ConsumetAPI.Endpoint.AnilistEndpoint.Provider.gogoanime
                    )
                )

                return API.request(consumetApi, endpoint, ConsumetAPI.StreamingLinksPayload.self)
                    .map { $0?.sources ?? [] }
                    .map(convertConsumetSourceToSource)
                    .eraseToEffect()
        }
    }()
}

// MARK: - Source

// MARK: Consumet Converters

fileprivate func convertConsumetSourceToSource(sources: [ConsumetAPI.StreamingLink]) -> [Source] {
    zip(sources.indices, sources)
        .map { (index, streamingLink) in
            Source(
                id: "\(index)",
                url: URL(string: streamingLink.url)!,
                provider: "Unknown",
                subbed: false
            )
        }
}

fileprivate func convertConsumetEpisodeToEpisode(episodes: [ConsumetAPI.Episode]) -> [Episode] {
    episodes.compactMap { episode in
        var thumbnailImages = [ImageSize]()

        if let thumbnailString = episode.image, let thumbnailURL = URL(string: thumbnailString) {
            thumbnailImages.append(.original(thumbnailURL))
        }

        return Episode(
            id: episode.id,
            name: episode.title ?? "Untitled",
            number: episode.number,
            description: episode.description ?? "No description available for this episode.",
            thumbnail: thumbnailImages,
            length: nil
        )
    }
}

// MARK: - Consumet

fileprivate class ConsumetAPI: APIRoute {
    enum Endpoint: Equatable {
        case anilist(AnilistEndpoint)
        case enime(EnimeEndpoint)

        enum EnimeEndpoint: Equatable {
            case watch(episodeId: String)
            case query(String)
            case info(animeId: String)
        }

        enum AnilistEndpoint: Equatable {
            case animeInfo(animeId: Int, options: AnimeInfoOptions)
            case streamingLinks(episodeId: String, provider: Provider = .gogoanime)

            struct AnimeInfoOptions: Equatable {
                var dub: Bool = false
                var provider: Provider = .gogoanime
            }

            enum Provider: String, CaseIterable, Decodable {
                case gogoanime
                case zoro
            }
        }
    }

    var baseURL: URL {
        URL(string: "https://api.consumet.org")!
    }

    let router: AnyParserPrinter<URLRequestData, Endpoint> = {
        OneOf {
            Route(.case(Endpoint.enime)) {
                Path { "anime"; "enime" }

                OneOf {
                    Route(.case(Endpoint.EnimeEndpoint.query)) {
                        Path { Parse(.string) }
                    }
                    Route(.case(Endpoint.EnimeEndpoint.info(animeId:))) {
                        Path { "info" }
                        Query {
                            Field("id") { Parse(.string) }
                        }
                    }
                    Route(.case(Endpoint.EnimeEndpoint.watch(episodeId:))) {
                        Path { "watch" }
                        Query {
                            Field("episodeId") { Parse(.string) }
                        }
                    }
                }
            }
            Route(.case(Endpoint.anilist)) {
                Path { "meta"; "anilist" }

                OneOf {
                    Route(.case(Endpoint.AnilistEndpoint.animeInfo(animeId:options:))) {
                        Path { "info"; Int.parser() }
                        Parse(.memberwise(Endpoint.AnilistEndpoint.AnimeInfoOptions.init(dub:provider:))) {
                            Query {
                                Field("dub") { Bool.parser() }
                                Field("provider") { Endpoint.AnilistEndpoint.Provider.parser() }
                            }
                        }
                    }
                    Route(.case(Endpoint.AnilistEndpoint.streamingLinks(episodeId:provider:))) {
                        Path { "watch"; Parse(.string) }
                        Query {
                            Field("provider") { Endpoint.AnilistEndpoint.Provider.parser() }
                        }
                    }
                }
            }
        }
        .eraseToAnyParserPrinter()
    }()

    func applyHeaders(request: inout URLRequest) {}
}

fileprivate extension ConsumetAPI {
    struct Anime: Equatable, Decodable {
        let id: String
        let subOrDub: AudioType
        let episodes: [Episode]

        enum AudioType: String, Equatable, Decodable {
            case sub, dub
        }
    }

    struct Episode: Equatable, Decodable {
        let id: String
        let number: Int
        let title: String?
        let image: String?
        let description: String?
    }

    struct StreamingLinksPayload: Decodable {
        let headers: HeaderReferer
        let sources: [StreamingLink]
    }

    struct HeaderReferer: Decodable {
        let Referer: String
    }

    struct StreamingLink: Decodable {
        let url: String
        let isM3U8: Bool
    }
}

// MARK: - Enime Route

fileprivate class EnimeAPI: APIRoute {

    // MARK: Enime Route Endpoints

    enum Endpoint: Equatable {
        case mapping(ExternalProvider)
        case fetchEpisodes(animeId: String)
        case episode(String)
        case source(id: String)

        struct ExternalProvider: Equatable, Decodable {
            var provider: Provider
            var id: String
            
            enum Provider: String, CaseIterable, Equatable, Decodable {
                case kitsu
                case mal
                case anilist
            }
        }
        
        struct PageSize: Equatable {
            var page = 1
            var perPage = 10
        }
    }

    let router: AnyParserPrinter<URLRequestData, Endpoint> = {
        OneOf {
            Route(.case(Endpoint.source(id:))) {
                Path { "source"; Parse(.string) }
            }
            Route(.case(Endpoint.episode)) {
                Path { "episode"; Parse(.string) }
            }
            Route(.case(Endpoint.mapping)) {
                Path { "mapping" }
                Parse(.memberwise(Endpoint.ExternalProvider.init)) {
                    Path { Endpoint.ExternalProvider.Provider.parser(); Parse(.string) }
                }
            }
            Route(.case(Endpoint.fetchEpisodes(animeId:))) {
                Path { "anime"; Parse(.string); "episodes" }
            }
        }
        .eraseToAnyParserPrinter()
    }()
    
    let baseURL = URL(string: "https://api.enime.moe")!
    
    func applyHeaders(request: inout URLRequest) {}
}

fileprivate extension EnimeAPI {

    // MARK: - DataResponse
    struct DataResponse<T: Decodable>: Decodable {
        let data: [T]
        let meta: Meta
    }

    // MARK: - Meta
    struct Meta: Decodable {
        let total: Int
        let lastPage: Int
        let currentPage: Int
        let perPage: Int
        let next: Int
    }

    // MARK: - Episode
    struct Episode: Decodable {
        let id: String
        let number: Int
        let title: String?
        let titleVariations: Title?
        let description: String?
        let image: String?
        let airedAt: String?
        let sources: [Source]
    }

    // MARK: - Source
    struct Source: Decodable {
        let id: String
        let url: String
        let target: String
        let priority: Int
        let website: String?
        let subtitle: Bool?
        let browser: Bool?
    }

    struct Anime: Decodable {
        let id: String
        let anilistId: Int
    }

    // MARK: - Title
    struct Title: Decodable {
        let native: String?
        let romaji: String?
        let english: String?
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

