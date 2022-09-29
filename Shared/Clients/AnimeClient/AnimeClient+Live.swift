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
        let kitsuApi = KitsuAPI()
        let enimeApi = EnimeAPI()
        let consumetApi = ConsumetAPI()

        return Self {
            let query = KitsuAPI.GlobalTrending.createQuery(
                .init(
                    first: 25
                )
            )
                .format()
            let endpoint = KitsuAPI.Endpoint.graphql(
                .init(
                    query: query
                )
            )
            let response = API.request(kitsuApi, endpoint, GraphQL.Response<KitsuAPI.GlobalTrending>.self)

            return response
                .map { $0?.data.globalTrending.nodes ?? [] }
                .map(convertKitsuAnimeToAnime(animes:))
                .eraseToEffect()
        } getTopUpcomingAnime: {
            let query = KitsuAPI.AnimeByStatus.createQuery(
                .init(
                    first: 25,
                    status: .UPCOMING
                )
            )
                .format()
            let endpoint = KitsuAPI.Endpoint.graphql(.init(query: query))
            let response = API.request(kitsuApi, endpoint, GraphQL.Response<KitsuAPI.AnimeByStatus>.self)

            return response
                .map { $0?.data.animeByStatus.nodes ?? [] }
                .map(sortBasedOnUserRank(animes:))
                .map(convertKitsuAnimeToAnime(animes:))
                .eraseToEffect()
        } getTopAiringAnime: {
            let query = KitsuAPI.AnimeByStatus.createQuery(
                .init(
                    first: 25,
                    status: .CURRENT
                )
            )
                .format()
            let endpoint = KitsuAPI.Endpoint.graphql(.init(query: query))
            let response = API.request(kitsuApi, endpoint, GraphQL.Response<KitsuAPI.AnimeByStatus>.self)

            return response
                .map { $0?.data.animeByStatus.nodes ?? [] }
                .map(sortBasedOnUserRank(animes:))
                .map(convertKitsuAnimeToAnime(animes:))
                .eraseToEffect()
        } getHighestRatedAnime: {
            let query = KitsuAPI.AnimeByStatus.createQuery(
                .init(
                    first: 25,
                    status: .CURRENT
                )
            )
                .format()
            let endpoint = KitsuAPI.Endpoint.graphql(.init(query: query))
            let response = API.request(kitsuApi, endpoint, GraphQL.Response<KitsuAPI.AnimeByStatus>.self)

            return response
                .map { $0?.data.animeByStatus.nodes ?? [] }
                .map(sortBasedOnAvgRank(animes:))
                .map(convertKitsuAnimeToAnime(animes:))
                .eraseToEffect()
        } getMostPopularAnime: {
            let query = KitsuAPI.AnimeByStatus.createQuery(
                .init(
                    first: 25,
                    status: .CURRENT
                )
            )
                .format()
            let endpoint = KitsuAPI.Endpoint.graphql(.init(query: query))
            let response = API.request(kitsuApi, endpoint, GraphQL.Response<KitsuAPI.AnimeByStatus>.self)

            return response
                .map { $0?.data.animeByStatus.nodes ?? [] }
                .map(sortBasedOnUserRank(animes:))
                .map(convertKitsuAnimeToAnime(animes:))
                .eraseToEffect()
        } searchAnimes: { query in
            let query = KitsuAPI.SearchAnimeByTitle.createQuery(
                .init(
                    title: query,
                    first: 25
                )
            )
                .format()
            let endpoint = KitsuAPI.Endpoint.graphql(.init(query: query))
            let response = API.request(kitsuApi, endpoint, GraphQL.Response<KitsuAPI.SearchAnimeByTitle>.self)

            return response
                .map { $0?.data.searchAnimeByTitle.nodes ?? [] }
                .map(convertKitsuAnimeToAnime(animes:))
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
            switch episodeId {
            case .enime(let episodeId):
                let endpoint = ConsumetAPI.Endpoint.enime(.watch(episodeId: episodeId))
                return API.request(consumetApi, endpoint, ConsumetAPI.StreamingLinksPayload.self)
                    .map { $0?.sources ?? [] }
                    .map(convertConsumetSourceToSource(sources:))
                    .eraseToEffect()
            case .consumet(let episodeId):
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
        }
    }()
}

// MARK: - Kitsu to App Mapping

private func sortBasedOnAvgRank(animes: [KitsuAPI.Anime]) -> [KitsuAPI.Anime] {
    animes.sorted(by: { lhs, rhs in
        if let lhsRank = lhs.averageRatingRank, let rhsRank = rhs.averageRatingRank {
            return lhsRank < rhsRank
        } else if lhs.averageRatingRank != nil && rhs.averageRatingRank == nil {
            return true
        } else {
            return false
        }
    })
}

private func sortBasedOnUserRank(animes: [KitsuAPI.Anime]) -> [KitsuAPI.Anime] {
    animes.sorted(by: { lhs, rhs in
        if let lhsRank = lhs.userCountRank, let rhsRank = rhs.userCountRank {
            return lhsRank < rhsRank
        } else if lhs.userCountRank != nil && rhs.userCountRank == nil {
            return true
        } else {
            return false
        }
    })
}

private func convertKitsuAnimeToAnime(animes: [KitsuAPI.Anime]) -> [Anime] {
    animes.compactMap { anime in
        if anime.subtype == .MUSIC {
            return nil
        }

        let posterImageOriginal: [ImageSize]
        let bannerImageOriginal: [ImageSize]

        if let posterImgOrigStr = anime.posterImage?.original.url,
           let url = URL(string: posterImgOrigStr) {
            posterImageOriginal = [.original(url)]
        } else {
            posterImageOriginal = []
        }

        if let bannerImgOrigStr = anime.posterImage?.original.url,
           let url = URL(string: bannerImgOrigStr) {
            bannerImageOriginal = [.original(url)]
        } else {
            bannerImageOriginal = []
        }

        let posterImageSizes = (anime.posterImage?.views ?? []).compactMap(convertImageViewToImage(imageView:)) + posterImageOriginal
        let coverImageSizes = (anime.bannerImage?.views ?? []).compactMap(convertImageViewToImage(imageView:)) + bannerImageOriginal

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy/MM/dd"

        var mappings = anime.mappings.nodes.compactMap { mapping -> Anime.AnimeListID? in
            switch mapping.externalSite {
            case .MYANIMELIST_ANIME:
                return Anime.AnimeListID.mal(mapping.externalId)
            case .ANILIST_ANIME:
                return Anime.AnimeListID.anilist(mapping.externalId)
            default:
                return nil
            }
        }

        mappings.append(Anime.AnimeListID.kitsu(anime.id))

        return Anime(
            id: .kitsu(anime.id),
            title: anime.titles.translated ?? anime.titles.romanized ?? anime.titles.canonical ?? anime.titles.original ?? "Untitled",
            description: anime.description.en ?? "Anime description is not available.",
            posterImage: .init(posterImageSizes),
            coverImage: .init(coverImageSizes),
            categories: anime.categories.nodes.compactMap { $0.title.en },
            status: .init(rawValue: anime.status.rawValue.lowercased())!,
            format: anime.subtype == .MOVIE ? .movie : .tv,
            studios: anime.productions.nodes.map({ $0.company.name }).removingDuplicates(),
            releaseDate: dateFormatter.date(from: anime.startDate ?? ""),
            mappings: mappings
        )
    }
}

private func convertImageViewToImage(imageView: KitsuAPI.ImageView) -> ImageSize? {
    guard let url = URL(string: imageView.url) else { return nil }

    let name = imageView.name

    if name == "tiny" {
        return ImageSize.tiny(url)
    } else if name == "small" {
        return ImageSize.small(url)
    } else if name == "medium" {
        return ImageSize.medium(url)
    } else if name == "large" {
        return ImageSize.large(url)
    } else {
        // Huh????
        return nil
    }
}

// MARK: - Kitsu API Endpoints

fileprivate class KitsuAPI: APIRoute {
    enum Endpoint: Equatable {
        case graphql(GraphQL.Paylod)
    }

    let router: AnyParserPrinter<URLRequestData, Endpoint> = {
        OneOf {
            Route(.case(Endpoint.graphql)) {
                Method.post
                Path {
                    "graphql"
                }
                Body(.json(GraphQL.Paylod.self))
            }
        }
        .eraseToAnyParserPrinter()
    }()

    let baseURL = URL(string: "https://kitsu.io/api")!

    func applyHeaders(request: inout URLRequest) {
        let bodyCount = request.httpBody?.count ?? 0
        let requestHeaders = [
            "Content-Type": "application/json",
            "Content-Length": "\(bodyCount)"
        ]

        for header in requestHeaders {
            request.addValue(header.value, forHTTPHeaderField: header.key)
        }
    }
}

// MARK: - Kitsu Queries

fileprivate extension KitsuAPI {
    struct GlobalTrending: GraphQLQuery {
        let globalTrending: GraphQL.NodeList<Anime>

        enum Argument: GraphQLArgument {
            case mediaType(MediaType)
            case first(Int)

            enum MediaType: String, EnumValueRepresentable {
                case ANIME
                case MANGA
            }

            var description: String {
                switch self {
                case .mediaType:
                    return "mediaType"
                case .first:
                    return "first"
                }
            }

            func getValue() -> ArgumentValueRepresentable {
                switch self {
                case .mediaType(let mediaType):
                    return mediaType
                case .first(let int):
                    return int
                }
            }
        }

        struct ArgumentOptions {
            var first: Int = 7
        }

        static func createQuery(
            _ arguments: ArgumentOptions
        ) -> Weave {
            Weave(.query) {
                Object(GlobalTrending.self) {
                    Anime.createQueryObject(GraphQL.NodeList<Anime>.CodingKeys.nodes)
                    GraphQL.PageInfo.createQueryObject(GraphQL.NodeList<Anime>.CodingKeys.pageInfo)
                }
                .argument(Argument.mediaType(.ANIME))
                .argument(Argument.first(arguments.first))
            }
        }
    }

    struct SearchAnimeByTitle: GraphQLQuery {
        let searchAnimeByTitle: GraphQL.NodeList<Anime>

        enum Argument: GraphQLArgument {
            case title(String)
            case first(Int)

            var description: String {
                switch self {
                case .title:
                    return "title"
                case .first:
                    return "first"
                }
            }

            func getValue() -> ArgumentValueRepresentable {
                switch self {
                case .title(let title):
                    return title
                case .first(let first):
                    return first
                }
            }
        }

        struct ArgumentOptions {
            let title: String
            var first: Int = 10
        }

        static func createQuery(
            _ arguments: ArgumentOptions
        ) -> Weave {
            Weave(.query) {
                Object(SearchAnimeByTitle.self) {
                    Anime.createQueryObject(GraphQL.NodeList<Anime>.CodingKeys.nodes)
                    GraphQL.PageInfo.createQueryObject(GraphQL.NodeList<Anime>.CodingKeys.pageInfo)
                }
                .argument(Argument.title(arguments.title))
                .argument(Argument.first(arguments.first))
            }
        }
    }

    struct AnimeByStatus: GraphQLQuery {
        let animeByStatus: GraphQL.NodeList<Anime>

        struct ArgumentOptions {
            let first: Int
            let status: Anime.Status
        }

        enum Argument: GraphQLArgument {
            case first(Int)
            case status(Anime.Status)

            func getValue() -> ArgumentValueRepresentable {
                switch self {
                case .first(let int):
                    return int
                case .status(let status):
                    return status
                }
            }

            var description: String {
                switch self {
                case .first:
                    return "first"
                case .status:
                    return "status"
                }
            }
        }

        static func createQuery(_ arguments: ArgumentOptions) -> Weave {
            Weave(.query) {
                Object(Self.self) {
                    Anime.createQueryObject(GraphQL.NodeList<Anime>.CodingKeys.nodes)
                    GraphQL.PageInfo.createQueryObject(GraphQL.NodeList<Anime>.CodingKeys.pageInfo)
                }
                .argument(Argument.first(arguments.first))
                .argument(Argument.status(arguments.status))
            }
        }
    }

    struct FindAnimeById: GraphQLQuery {
        let findAnimeById: Anime

        struct ArgumentOptions {
            let id: String
            var episodesOnly = false
        }

        enum Argument: GraphQLArgument {
            case id(String)

            func getValue() -> ArgumentValueRepresentable {
                switch self {
                case .id(let str):
                    return str
                }
            }

            var description: String {
                switch self {
                case .id:
                    return "id"
                }
            }
        }

        static func createQuery(_ arguments: ArgumentOptions) -> Weave {
            Weave(.query) {
                Anime.createQueryObject(CodingKeys.findAnimeById)
                    .argument(Argument.id(arguments.id))
            }
        }
    }
}

// MARK: - Kitsu GraphQL Models

fileprivate extension KitsuAPI {
    struct MediaProductionConnection: Decodable {
        let nodes: [MediaProduction]

        static func createQueryObject(
            _ name: CodingKey
        ) -> Object {
            Object(name) {
                MediaProduction.createQueryObject(CodingKeys.nodes)
            }
            .argument(key: "first", value: 20)
        }
    }

    struct MediaProduction: Decodable {
        let company: Producer
        let role: Role

        enum Role: String, Decodable {
            case PRODUCER
            case LICENSOR
            case STUDIO
            case SERIALIZATION
        }

        static func createQueryObject(
            _ name: CodingKey
        ) -> Object {
            Object(name) {
                Producer.createQueryObject(CodingKeys.company)
                Field(CodingKeys.role)
            }
        }
    }

    struct Producer: Decodable {
        let name: String

        static func createQueryObject(
            _ name: CodingKey
        ) -> Object {
            Object(name) {
                Field(CodingKeys.name)
            }
        }
    }

    struct CategoryConnection: Decodable {
        let nodes: [Category]

        static func createQueryObject(
            _ name: CodingKey
        ) -> Object {
            Object(name) {
                Category.createQueryObject(CodingKeys.nodes)
            }
        }
    }

    struct Category: Decodable {
        let title: Localization

        static func createQueryObject(
            _ name: CodingKey
        ) -> Object {
            Object(name) {
                Field(CodingKeys.title)
            }
        }
    }

    struct Localization: Decodable {
        let en: String?
    }

    struct Image: Decodable {
        let blurHash: String?
        let original: ImageView
        let views: [ImageView]

        static func createQueryObject(
            _ name: CodingKey
        ) -> Object {
            Object(name) {
                ImageView.createQueryObject(CodingKeys.original)
                ImageView.createQueryObject(CodingKeys.views)
            }
        }
    }

    struct ImageView: Decodable {
        let name: String
        let url: String
        let height: Int?
        let width: Int?

        static func createQueryObject(
            _ name: CodingKey
        ) -> Object {
            Object(name) {
                Field(CodingKeys.name)
                Field(CodingKeys.url)
                Field(CodingKeys.width)
                Field(CodingKeys.height)
            }
        }
    }

    struct Titles: Decodable {
        let canonical: String?
        let original: String?
        let preferred: String?
        let romanized: String?
        let translated: String?

        static func createQueryObject(
            _ name: CodingKey,
            _ includePreferred: Bool = true,
            _ includeCanonical: Bool = true
        ) -> Object {
            Object(name) {
                Field(CodingKeys.preferred)
                    .include(if: includePreferred)
                Field(CodingKeys.canonical)
                    .include(if: includeCanonical)
                Field(CodingKeys.original)
                Field(CodingKeys.translated)
                Field(CodingKeys.romanized)
            }
        }
    }

    struct MappingConnection: Decodable {
        let nodes: [Mapping]  // Stub

        static func createQueryObject(
            _ name: CodingKey
        ) -> Object {
            Object(name) {
                Mapping.createQueryObject(CodingKeys.nodes)
            }
            .argument(key: "first", value: 20)
        }
    }

    struct Mapping: Decodable {
        let id: String
        let externalId: String
        let externalSite: ExternalSite

        enum ExternalSite: String, Decodable {
            case MYANIMELIST_ANIME
            case MYANIMELIST_MANGA
            case MYANIMELIST_CHARACTERS
            case MYANIMELIST_PEOPLE
            case MYANIMELIST_PRODUCERS
            case ANILIST_ANIME
            case ANILIST_MANGA
            case THETVDB
            case THETVDB_SERIES
            case THETVDB_SEASON
            case ANIDB
            case ANIMENEWSNETWORK
            case MANGAUPDATES
            case HULU
            case IMDB_EPISODES
            case AOZORA
            case TRAKT
            case MYDRAMALIST
        }

        static func createQueryObject(
            _ name: CodingKey
        ) -> Object {
            Object(name) {
                Field(CodingKeys.id)
                Field(CodingKeys.externalSite)
                Field(CodingKeys.externalId)
            }
        }
    }

    struct Anime: Decodable {

        // Media

        let id: String
        let slug: String
        let description: Localization
        let categories: CategoryConnection
        let posterImage: Image?
        let bannerImage: Image?
        let titles: Titles
        let averageRating: Float?
        let averageRatingRank: Int?
        let status: Status
        let userCountRank: Int?
        let productions: MediaProductionConnection
        let ageRating: AgeRating?
        let startDate: String?
        let mappings: MappingConnection

        // Anime Only

        let season: ReleaseSeason?
        let youtubeTrailerVideoId: String?
        let totalLength: Int?
        let subtype: Subtype?

        enum Status: String, Decodable, EnumRawValueRepresentable {
            case TBA
            case FINISHED
            case CURRENT
            case UPCOMING
            case UNRELEASED
        }

        enum Subtype: String, Decodable {
            case TV
            case SPECIAL
            case OVA
            case ONA
            case MOVIE
            case MUSIC
        }

        enum ReleaseSeason: String, Decodable {
            case WINTER
            case SPRING
            case SUMMER
            case FALL
        }

        enum AgeRating: String, Decodable {
            case G
            case PG
            case R
            case R18
        }

        static func createQueryObject(
            _ name: CodingKey
        ) -> Object {
            Object(name) {
                Field(CodingKeys.id)
                Field(CodingKeys.slug)
                Field(CodingKeys.description)
                CategoryConnection.createQueryObject(CodingKeys.categories)
                    .slice(amount: 3)
                Image.createQueryObject(CodingKeys.posterImage)
                Image.createQueryObject(CodingKeys.bannerImage)
                Titles.createQueryObject(CodingKeys.titles)
                Field(CodingKeys.averageRating)
                Field(CodingKeys.averageRatingRank)
                Field(CodingKeys.status)
                Field(CodingKeys.userCountRank)
                MediaProductionConnection.createQueryObject(CodingKeys.productions)
                Field(CodingKeys.ageRating)
                Field(CodingKeys.startDate)

                MappingConnection.createQueryObject(CodingKeys.mappings)

                InlineFragment("Anime") {
                    Field(CodingKeys.season)
                    Field(CodingKeys.youtubeTrailerVideoId)
                    Field(CodingKeys.totalLength)
                    Field(CodingKeys.subtype)
                }
            }
        }
    }
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
            id: .consumet(episode.id),
            name: episode.title ?? "Untitled",
            number: episode.number,
            description: episode.description ?? "No description available for this episode.",
            thumbnail: thumbnailImages,
            length: nil
        )
    }
}

// MARK: - Enime Converters

fileprivate func convertEnimeEpisodeToEpisode(episodes: [EnimeAPI.Episode]) -> [Episode] {
    episodes.compactMap { episode in
        var thumbnailImages = [ImageSize]()

        if let thumbnailString = episode.image, let thumbnailURL = URL(string: thumbnailString) {
            thumbnailImages.append(.original(thumbnailURL))
        }

        return Episode(
            id: .enime(episode.id),
            name: episode.title ?? "Untitled",
            number: episode.number,
            description: episode.description ?? "No description available for this episode.",
            thumbnail: thumbnailImages,
            length: nil
        )
    }
}

fileprivate func convertEnimeSourceToSource(sources: [EnimeAPI.Source]) -> [Source] {
    sources.compactMap { source in
        guard let url = URL(string: source.url) else {
            return nil
        }

        return Source(
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

