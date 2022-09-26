//
//  ListClient+Kitsu.swift
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

extension ListClient {
    static let kitsu: Self = {
        let api = KitsuAPI()

        return Self(
            topTrendingAnime: {
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
                let response = API.request(api, endpoint, GraphQL.Response<KitsuAPI.GlobalTrending>.self)

                return response
                    .map { $0?.data.globalTrending.nodes ?? [] }
                    .map(convertKitsuAnimeToAnime(animes:))
                    .eraseToEffect()
            },
            topUpcomingAnime: {
                let query = KitsuAPI.AnimeByStatus.createQuery(
                    .init(
                        first: 25,
                        status: .UPCOMING
                    )
                )
                    .format()
                let endpoint = KitsuAPI.Endpoint.graphql(.init(query: query))
                let response = API.request(api, endpoint, GraphQL.Response<KitsuAPI.AnimeByStatus>.self)

                return response
                    .map { $0?.data.animeByStatus.nodes ?? [] }
                    .map(sortBasedOnUserRank(animes:))
                    .map(convertKitsuAnimeToAnime(animes:))
                    .eraseToEffect()
            },
            topAiringAnime: {
                let query = KitsuAPI.AnimeByStatus.createQuery(
                    .init(
                        first: 25,
                        status: .CURRENT
                    )
                )
                    .format()
                let endpoint = KitsuAPI.Endpoint.graphql(.init(query: query))
                let response = API.request(api, endpoint, GraphQL.Response<KitsuAPI.AnimeByStatus>.self)

                return response
                    .map { $0?.data.animeByStatus.nodes ?? [] }
                    .map(sortBasedOnUserRank(animes:))
                    .map(convertKitsuAnimeToAnime(animes:))
                    .eraseToEffect()
            },
            highestRatedAnime: {
                let query = KitsuAPI.AnimeByStatus.createQuery(
                    .init(
                        first: 25,
                        status: .CURRENT
                    )
                )
                    .format()
                let endpoint = KitsuAPI.Endpoint.graphql(.init(query: query))
                let response = API.request(api, endpoint, GraphQL.Response<KitsuAPI.AnimeByStatus>.self)

                return response
                    .map { $0?.data.animeByStatus.nodes ?? [] }
                    .map(sortBasedOnAvgRank(animes:))
                    .map(convertKitsuAnimeToAnime(animes:))
                    .eraseToEffect()
            },
            mostPopularAnime: {
                let query = KitsuAPI.AnimeByStatus.createQuery(
                    .init(
                        first: 25,
                        status: .CURRENT
                    )
                )
                    .format()
                let endpoint = KitsuAPI.Endpoint.graphql(.init(query: query))
                let response = API.request(api, endpoint, GraphQL.Response<KitsuAPI.AnimeByStatus>.self)

                return response
                    .map { $0?.data.animeByStatus.nodes ?? [] }
                    .map(sortBasedOnUserRank(animes:))
                    .map(convertKitsuAnimeToAnime(animes:))
                    .eraseToEffect()
            },
            search: { query in
                let query = KitsuAPI.SearchAnimeByTitle.createQuery(
                    .init(
                        title: query,
                        first: 25
                    )
                )
                    .format()
                let endpoint = KitsuAPI.Endpoint.graphql(.init(query: query))
                let response = API.request(api, endpoint, GraphQL.Response<KitsuAPI.SearchAnimeByTitle>.self)

                return response
                    .map { $0?.data.searchAnimeByTitle.nodes ?? [] }
                    .map(convertKitsuAnimeToAnime(animes:))
                    .eraseToEffect()
            }
        )
    }()
}

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

        return Anime(
            id: .kitsu(anime.id),
            title: anime.titles.translated ?? anime.titles.romanized ?? anime.titles.canonical ?? anime.titles.original ?? "Untitled",
            description: anime.description.en ?? "Anime description is not available.",
            posterImage: .init(posterImageSizes),
            coverImage: .init(coverImageSizes),
            categories: anime.categories.nodes.compactMap { $0.title.en },
            status: .init(rawValue: anime.status.rawValue.lowercased())!,
            format: anime.subtype == .MOVIE ? .movie : .tv,
            studios: anime.productions.nodes.map({ $0.company.name }).removingDuplicates()
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

// MARK: API Endpoints

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

// MARK: Kitsu Queries

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
}

// MARK: Kitsu GraphQL Models

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

        // Anime Only

        let releaseSeason: ReleaseSeason?
        let youtubeTrailerVideoId: String?
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
            _ media: Bool = true
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

                Field(CodingKeys.subtype)
                    .skip(if: media)
            }
        }
    }
}
