//
//  AnimeListClient+Kitsu.swift
//  Anime Now!
//
//  Created by Erik Bautista on 9/3/22.
//
// Kitsu API
// https://kitsu.docs.apiary.io/#introduction/json:api

import Foundation
import ComposableArchitecture
import URLRouting
import SociableWeaver

// MARK: Live

extension AnimeListClient {
    static let kitsu: Self = {
        let router = KitsuRoute()

        return Self(
            authenticate: { .none },
            topTrendingAnime: {
                let query = GlobalTrending.createQuery(
                    .init(
                        first: 25
                    )
                )
                    .format()
                let endpoint = KitsuRoute.Endpoint.graphql(
                    .init(
                        query: query
                    )
                )
                let response = API.request(router, endpoint, GraphQL.Response<GlobalTrending>.self)

                return response
                    .map { $0?.data.globalTrending.nodes ?? [] }
                    .map(convertKitsuAnimeToAnime(animes:))
                    .eraseToEffect()
            },
            topUpcomingAnime: {
                let query = AnimeByStatus.createQuery(
                    .init(
                        first: 25,
                        status: .UPCOMING
                    )
                )
                    .format()
                let endpoint = KitsuRoute.Endpoint.graphql(.init(query: query))
                let response = API.request(router, endpoint, GraphQL.Response<AnimeByStatus>.self)

                return response
                    .map { $0?.data.animeByStatus.nodes ?? [] }
                    .map(sortBasedOnUserRank(animes:))
                    .map(convertKitsuAnimeToAnime(animes:))
                    .eraseToEffect()
            },
            topAiringAnime: {
                let query = AnimeByStatus.createQuery(
                    .init(
                        first: 25,
                        status: .CURRENT
                    )
                )
                    .format()
                let endpoint = KitsuRoute.Endpoint.graphql(.init(query: query))
                let response = API.request(router, endpoint, GraphQL.Response<AnimeByStatus>.self)

                return response
                    .map { $0?.data.animeByStatus.nodes ?? [] }
                    .map(sortBasedOnUserRank(animes:))
                    .map(convertKitsuAnimeToAnime(animes:))
                    .eraseToEffect()
            },
            highestRatedAnime: {
                let query = AnimeByStatus.createQuery(
                    .init(
                        first: 25,
                        status: .CURRENT
                    )
                )
                    .format()
                let endpoint = KitsuRoute.Endpoint.graphql(.init(query: query))
                let response = API.request(router, endpoint, GraphQL.Response<AnimeByStatus>.self)

                return response
                    .map { $0?.data.animeByStatus.nodes ?? [] }
                    .map(sortBasedOnAvgRank(animes:))
                    .map(convertKitsuAnimeToAnime(animes:))
                    .eraseToEffect()
            },
            mostPopularAnime: {
                let query = AnimeByStatus.createQuery(
                    .init(
                        first: 25,
                        status: .CURRENT
                    )
                )
                    .format()
                let endpoint = KitsuRoute.Endpoint.graphql(.init(query: query))
                let response = API.request(router, endpoint, GraphQL.Response<AnimeByStatus>.self)

                return response
                    .map { $0?.data.animeByStatus.nodes ?? [] }
                    .map(sortBasedOnUserRank(animes:))
                    .map(convertKitsuAnimeToAnime(animes:))
                    .eraseToEffect()
            },
            episodes: { animeId in
                guard case let .kitsu(animeId) = animeId else {
                    return Effect.none
                }
                let query = FetchEpisodesFromAnime.createQuery(
                    .init(
                        id: animeId
                    )
                )
                    .format()
                let endpoint = KitsuRoute.Endpoint.graphql(.init(query: query))
                let response = API.request(router, endpoint, GraphQL.Response<FetchEpisodesFromAnime>.self)

                return response
                    .map { $0?.data.findAnimeById.episodes.nodes ?? [] }
                    .map(convertKitsuEpisodeToEpisode(episodes:))
                    .eraseToEffect()
            }
        )
    }()
}

private func sortBasedOnAvgRank(animes: [AnimeListClient.Anime]) -> [AnimeListClient.Anime] {
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

private func sortBasedOnUserRank(animes: [AnimeListClient.Anime]) -> [AnimeListClient.Anime] {
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

private func convertKitsuAnimeToAnime(animes: [AnimeListClient.Anime]) -> [Anime] {
    animes.compactMap { anime in
        if anime.subtype == .MUSIC {
            return nil
        }

        let posterImageOriginal: [Anime.Image]
        let bannerImageOriginal: [Anime.Image]

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

        return Anime(
            id: .kitsu(anime.id),
            title: anime.titles.translated ?? anime.titles.romanized ?? anime.titles.canonical ?? anime.titles.original ?? "Untitled",
            description: anime.description.en ?? "Anime description is not available.",
            posterImage: .init(posterImageSizes),
            coverImage: .init(coverImageSizes),
            categories: anime.categories.nodes.compactMap { $0.title.en },
            status: .init(rawValue: anime.status.rawValue.lowercased())!,
            format: anime.subtype == .MOVIE ? .movie : .show
        )
    }
}

private func convertImageViewToImage(imageView: AnimeListClient.ImageView) -> Anime.Image? {
    guard let url = URL(string: imageView.url) else { return nil }

    let name = imageView.name

    if name == "tiny" {
        return Anime.Image.tiny(url)
    } else if name == "small" {
        return Anime.Image.small(url)
    } else if name == "medium" {
        return Anime.Image.medium(url)
    } else if name == "large" {
        return Anime.Image.large(url)
    } else {
        // Huh????
        return nil
    }
}

private func convertKitsuEpisodeToEpisode(episodes: [AnimeListClient.Episode]) -> [Episode] {
    episodes.map { episode in
        var thumbnailSizes: [Anime.Image] = []

        if let originalUrl = episode.thumbnail?.original.url,
           let originalImage = URL(string: originalUrl) {
            thumbnailSizes.append(.original(originalImage))
        }

        thumbnailSizes.append(contentsOf: (episode.thumbnail?.views ?? []).compactMap(convertImageViewToImage(imageView:)))

        return Episode(
            id: episode.id,
            name: episode.titles.translated ?? episode.titles.romanized ?? episode.titles.canonical ?? "Episode \(episode.number)",
            number: episode.number,
            description: episode.description.en ?? "Description not available for this episode.",
            thumbnail: thumbnailSizes,
            length: episode.length
        )
    }
}


// MARK: API Endpoints

fileprivate class KitsuRoute: APIRoute {
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

// MARK: Kitsu Queries

fileprivate extension AnimeListClient {
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
                    Anime.createQueryObject(GraphQL.NodeList<Anime>.CodingKeys.nodes, false)
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
                Anime.createQueryObject(CodingKeys.findAnimeById, false)
                    .argument(Argument.id(arguments.id))
            }
        }
    }

    struct FetchEpisodesFromAnime: GraphQLQuery {
        let findAnimeById: EpisodesContainer

        struct EpisodesContainer: Decodable {
            let episodes: EpisodeConnection
        }

        struct ArgumentOptions {
            let id: String
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
                Object("findAnimeById") {
                    EpisodeConnection.createQueryObject("episodes")
                }
                .argument(Argument.id(arguments.id))
            }
        }
    }
}

// MARK: Kitsu GraphQL Models

fileprivate extension AnimeListClient {
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

    struct EpisodeConnection: Decodable {
        let nodes: [Episode]
        let pageInfo: GraphQL.PageInfo

        static func createQueryObject(
            _ name: String
        ) -> Object {
            Object(name) {
                Episode.createQueryObject(CodingKeys.nodes)
                GraphQL.PageInfo.createQueryObject(CodingKeys.pageInfo)
            }
            .argument(key: "first", value: 25)
        }
    }

    struct Episode: Decodable {
        let id: String
        let description: Localization
        let length: Int
        let number: Int
        let thumbnail: Image?
        let titles: Titles

        static func createQueryObject(
            _ name: CodingKey
        ) -> Object {
            Object(name) {
                Field(CodingKeys.id)
                Field(CodingKeys.description)
                Field(CodingKeys.length)
                Field(CodingKeys.number)
                Image.createQueryObject(CodingKeys.thumbnail)
                Titles.createQueryObject(CodingKeys.titles, false)
            }
        }
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

        // Anime Only

        let releaseSeason: ReleaseSeason?
        let youtubeTrailerVideoId: String?
//        let episodeCount: Int?
        let totalLenght: Int?
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

        static func createQueryObject(
            _ name: CodingKey,
            _ media: Bool = true,
            _ episodesOnly: Bool = false
        ) -> Object {
            Object(name) {
                Field(CodingKeys.id)
                    .skip(if: episodesOnly)
                Field(CodingKeys.slug)
                    .skip(if: episodesOnly)
                Field(CodingKeys.description)
                    .skip(if: episodesOnly)
                CategoryConnection.createQueryObject(CodingKeys.categories)
                    .slice(amount: 3)
                    .skip(if: episodesOnly)
                Image.createQueryObject(CodingKeys.posterImage)
                    .skip(if: episodesOnly)
                Image.createQueryObject(CodingKeys.bannerImage)
                    .skip(if: episodesOnly)
                Titles.createQueryObject(CodingKeys.titles)
                    .skip(if: episodesOnly)
                Field(CodingKeys.averageRating)
                    .skip(if: episodesOnly)
                Field(CodingKeys.averageRatingRank)
                    .skip(if: episodesOnly)
                Field(CodingKeys.status)
                    .skip(if: episodesOnly)
                Field(CodingKeys.userCountRank)
                    .skip(if: episodesOnly)

                Field(CodingKeys.subtype)
                    .skip(if: media || episodesOnly)
            }
        }
    }
}
