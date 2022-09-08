//
//  ListClient+Kitsu.swift
//  Anime Now! (macOS)
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
        let router = KitsuRoute()

        return Self(
            name:  { .kitsu },
            authenticate: { .none },
            trendingAnime: {
                let query = GlobalTrending.createQuery(
                    .init()
                )
                    .format()
                let endpoint = KitsuRoute.Endpoint.graphql(.init(query: query))
                let response = API.request(router, endpoint, GraphQL.Response<GlobalTrending>.self)

                return response
                    .map { $0?.data.globalTrending.nodes ?? [] }
                    .map { (animes: [Anime]) in
                        animes.map { anime in
                            Anime_Now_.Anime(
                                id: anime.id,
                                title: anime.titles.translated ?? anime.titles.romanized ?? anime.titles.canonical,
                                description: anime.description.en,
                                posterImage: URL(string: anime.posterImage?.original.url ?? "/")!,
                                coverImage: URL(string: anime.bannerImage?.original.url ?? "/")!,
                                categories: anime.categories.nodes.map { $0.title.en },
                                status: .init(rawValue: anime.status.rawValue)!
                            )
                        }
                    }
                    .eraseToEffect()
            },
            recentlyReleasedAnime: {
                let query = AnimeByStatus.createQuery(
                    .init(
                        first: 20,
                        status: .CURRENT
                    )
                )
                    .format()
                let endpoint = KitsuRoute.Endpoint.graphql(.init(query: query))
                let response = API.request(router, endpoint, GraphQL.Response<AnimeByStatus>.self)

                return response
                    .map { $0?.data.animeByStatus.nodes ?? [] }
                    .map { (animes: [Anime]) in
                        animes.map { anime in
                            Anime_Now_.Anime(
                                id: anime.id,
                                title: anime.titles.translated ?? anime.titles.romanized ?? anime.titles.canonical,
                                description: anime.description.en,
                                posterImage: URL(string: anime.posterImage?.original.url ?? "/")!,
                                coverImage: URL(string: anime.bannerImage?.original.url ?? "/")!,
                                categories: anime.categories.nodes.map { $0.title.en },
                                status: .init(rawValue: anime.status.rawValue)!
                            )
                        }
                    }
                    .eraseToEffect()
            }
        )
    }()
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

fileprivate extension ListClient {
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
}

// MARK: Kitsu GraphQL Models

fileprivate extension ListClient {
    struct CategoryConnection: Decodable, GraphQLQueryObject {
        let nodes: [Category]

        static func createQueryObject(
            _ name: CodingKey
        ) -> Object {
            Object(name) {
                Category.createQueryObject(CodingKeys.nodes)
            }
        }
    }

    struct Category: Decodable, GraphQLQueryObject {
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
        let en: String
    }

    struct Episode: Decodable {
        let anime: Anime
        let description: Localization
        let id: String
        let length: Int
        let number: Int
        let thumbnail: Image?
        let titles: Titles
    }

    struct Image: Decodable, GraphQLQueryObject {
        let blurHash: String?
        let original: ImageView
        let views: [ImageView]?

        static func createQueryObject(
            _ name: CodingKey
        ) -> Object {
            Object(name) {
                ImageView.createQueryObject(CodingKeys.original)
            }
        }
    }

    struct ImageView: Decodable, GraphQLQueryObject {
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

    struct Titles: Decodable, GraphQLQueryObject {
        let canonical: String
        let preferred: String
        let romanized: String?
        let translated: String?

        static func createQueryObject(
            _ name: CodingKey
        ) -> Object {
            Object(name) {
                Field(CodingKeys.preferred)
                Field(CodingKeys.canonical)
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

        // Anime Only

        let releaseSeason: ReleaseSeason?
        let youtubeTrailerVideoId: String?
        let episodeCount: Int?
        let episodeLenght: Int?
        let episodes: GraphQL.NodeList<Episode>?
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

                Field(CodingKeys.subtype)
                    .skip(if: media)
            }
        }
    }
}
