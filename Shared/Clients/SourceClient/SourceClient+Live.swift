//
//  SourceClient+Live.swift
//  Anime Now!
//
//  Created by Erik Bautista on 9/12/22.
//

import Foundation
import ComposableArchitecture
import URLRouting
import Combine

extension SourceClient {
    static let live: Self = {
        let consumetApi = ConsumetAPI()
        let enimeApi = EnimeAPI()

        return SourceClient(
            episodes: { animeId in
                let provider: EnimeAPI.Endpoint.ExternalProvider
                if case let .kitsu(kitsuId) = animeId {
                    provider = .init(provider: .kitsu, id: kitsuId)
                } else if case let .anilist(anilistId) = animeId {
                    provider = .init(provider: .anilist, id: anilistId)
                } else {
                    provider = .init(provider: .mal, id: animeId.value)
                }

                // This retrieves all id mapping for various anime list/streaming platforms

                let mappingEndpoint = EnimeAPI.Endpoint.mapping(provider)
                let mappingResponse = API.request(enimeApi, mappingEndpoint, EnimeAPI.Anime.self)

//                return mappingResponse
//                    .tryCompactMap { mapping in
//                        guard let anilistId = mapping?.anilistId else {
//                            throw API.Error.badServerResponse("Failed to get anime id mapping.")
//                        }
//
//                        return anilistId
//                    }
//                    .mapError { $0 as? API.Error ?? .badServerResponse("Failed to get anime id mapping.") }
//                    .flatMap { (animeId: Int) in
//                        // Fetch dub episodes first
//                        API.request(
//                            consumetApi,
//                            .anilist(.animeInfo(animeId: animeId, options: .init())),
//                            ConsumetAPI.Anime.self
//                        )
//                    }
//                    .tryCompactMap {
//                        guard let anime = $0 else {
//                            throw API.Error.badServerResponse("Failed to get anilist anime for episodes.")
//                        }
//                        return anime.episodes
//                    }
//                    .map(convertConsumetEpisodeToEpisode(episodes:))
//                    .mapError { $0 as? API.Error ?? .badServerResponse("Failed to get anilist anime for episodes.") }
//                    .eraseToEffect()

                // TODO: Use both enime and consumet to retrieve episode info

                // Using Enime API for episode information provides a more high quality thumbnails and is faster to fetch at the moment.

                return mappingResponse
                    .tryCompactMap { anime in
                        if let id = anime?.id {
                            return id
                        } else {
                            throw API.Error.badServerResponse("Failed to get anime id mapping due to return empty.")
                        }
                    }
                    .mapError { $0 as? API.Error ?? .badServerResponse("Failed to get anime id mapping due to bad response.") }
                    .flatMap { id in
                        // Enime always returns subbed sources with subtitles.
                        API.request(
                            enimeApi,
                            EnimeAPI.Endpoint.fetchEpisodes(animeId: id),
                            [EnimeAPI.Episode].self
                        )
                    }
                    // TODO: merge with dub so we can get info if the anime episode supports dub.
                    .tryMap { episodes -> [EnimeAPI.Episode] in
                        if let episodes = episodes {
                            return episodes
                        } else {
                            throw API.Error.badServerResponse("There was an issue fetchign episodes for id: \(animeId).")
                        }
                    }
                    .map(convertEnimeEpisodeToEpisode(episodes:))
                    .mapError { $0 as? API.Error ?? .badServerResponse("Failed to fetch episodes.") }
                    .eraseToEffect()
            },
            sources: { episodeId in
                switch episodeId {
                case .enime(let episodeId):
                    let endpoint = ConsumetAPI.Endpoint.enime(.watch(episodeId: episodeId))
                    return API.request(consumetApi, endpoint, ConsumetAPI.StreamingLinksPayload.self)
                        .map { $0?.sources ?? [] }
                        .map(convertConumentEnimeSourceToSource(sources:))
                        .eraseToEffect()

//                    let endpoint = EnimeAPI.Endpoint.episode(episodeId)
//                    return API.request(enimeApi, endpoint, EnimeAPI.Episode.self)
//                        .map { $0?.sources ?? [] }
//                        .map(convertEnimeSourceToSource(sources:))
//                        .eraseToEffect()
                case .consumet(_):
                    return .init(value: [])
                case .zoro(_):
                    return .init(value: [])
                case .gogoanime(_):
                    return .init(value: [])
                }
            }
        )
    }()
}

// MARK: - Consumet Converters

fileprivate func convertConumentEnimeSourceToSource(sources: [ConsumetAPI.StreamingLink]) -> [EpisodeSource] {
    sources.map { streaminglink in
        EpisodeSource(
            id: "",
            url: URL(string: streaminglink.url)!,
            provider: "Unknown",
            subbed: false
        )
    }
}

fileprivate func convertConsumetEpisodeToEpisode(episodes: [ConsumetAPI.Episode]) -> [Episode] {
    episodes.compactMap { episode in
        var thumbainImages = [Anime.Image]()

        if let thumbnailString = episode.image, let thumbnailURL = URL(string: thumbnailString) {
            thumbainImages.append(.original(thumbnailURL))
        }

        return Episode(
            id: .consumet(episode.id),
            name: episode.title ?? "Episode \(episode.number)",
            number: episode.number,
            description: episode.description ?? "No description available for this episode.",
            thumbnail: thumbainImages,
            length: nil
        )
    }
}

// MARK: - Enime Converters

fileprivate func convertEnimeEpisodeToEpisode(episodes: [EnimeAPI.Episode]) -> [Episode] {
    episodes.compactMap { episode in
        var thumbainImages = [Anime.Image]()

        if let thumbnailString = episode.image, let thumbnailURL = URL(string: thumbnailString) {
            thumbainImages.append(.original(thumbnailURL))
        }

        return Episode(
            id: .enime(episode.id),
            name: episode.title ?? "Episode \(episode.number)",
            number: episode.number,
            description: episode.description ?? "No description available for this episode.",
            thumbnail: thumbainImages,
            length: nil
        )
    }
}

fileprivate func convertEnimeSourceToSource(sources: [EnimeAPI.Source]) -> [EpisodeSource] {
    sources.compactMap { source in
        guard let url = URL(string: source.url) else {
            return nil
        }

        return EpisodeSource(
            id: source.id,
            url: url,
            provider: source.website ?? "Unknown",
            subbed: source.subtitle ?? true
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
                var dub: Bool = true
                var provider: Provider = .gogoanime
            }

            enum Provider: String, CaseIterable, Decodable {
                case gogoanime
                case zoro
            }
        }
    }

    var baseURL: URL {
        URL(string: "https://consumet-api.herokuapp.com")!
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

    // MARK: - Mappings
    struct Mappings: Decodable {
        let mal, anidb, kitsu, anilist: Int
        let thetvdb, anisearch, livechart: Int
        let notifyMoe, animePlanet: String

        enum CodingKeys: String, CodingKey {
            case mal, anidb, kitsu, anilist, thetvdb, anisearch, livechart
            case notifyMoe = "notify.moe"
            case animePlanet = "anime-planet"
        }
    }

    struct Anime: Decodable {
        let id: String
        let anilistId: Int
        let mappings: Mappings
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
