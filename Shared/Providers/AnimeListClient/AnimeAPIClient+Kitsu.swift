//
//  KitsuAPIClient.swift
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

extension AnimeListClient {
    static let kitsu: Self = {
        return Self(
            name: { "Kitsu" },
            authenticate: {},
            trendingAnime: {
                let query = GlobalTrending.query.encode(removeOperation: true)
                let endpoint = KitsuEndpoint.graphql(.init(query: query))
                let response = API.request(endpoint, GraphQLResponse<GlobalTrending>.self)

                return response
                    .compactMap({ $0 })
                    .map { $0.data }
                    .map { $0.nodes }
                    .map { (animes: [Anime]) in
                        animes.map { anime in
                            Anime_Now_.Anime(
                                id: anime.id,
                                title: anime.titles.preferred,
                                description: anime.description.en,
                                posterImage: URL(string: anime.posterImage?.original.url ?? "/")!,
                                coverImage: URL(string: anime.bannerImage?.original.url ?? "/")!
                            )
                        }
                    }
                    .eraseToEffect()
            }
        )
    }()
}

// MARK: API Endpoints

fileprivate enum KitsuEndpoint: APIEndpoint {
    case graphql(GraphQLPaylod)

    static let router: AnyParserPrinter<URLRequestData, KitsuEndpoint> = {
        OneOf {
            Route(.case(KitsuEndpoint.graphql)) {
                Method.post
                Path {
                    "graphql"
                }
                Body(.json(GraphQLPaylod.self))
            }
        }
        .eraseToAnyParserPrinter()
    }()

    static let baseURL = URL(string: "https://kitsu.io/api")!

    static func applyHeaders(request: inout URLRequest) {
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

// MARK: Kitsu GraphQL Models

fileprivate protocol Media: Codable {
    var id: String { get }
    var description: AnimeListClient.Description { get }
    var posterImage: AnimeListClient.Image? { get }
    var bannerImage: AnimeListClient.Image? { get }
    var titles: AnimeListClient.Titles { get }
    var averageRating: Float? { get }
    var averageRatingRank: Int? { get }
    var slug: String { get }
}

fileprivate protocol Connection: Codable {
    associatedtype T: Codable
    var nodes: [T] { get }
    var pageInfo: AnimeListClient.PageInfo { get }
}

fileprivate extension AnimeListClient {
    // Queries

    struct GlobalTrending: Connection, GraphQLResponseResult {
        var nodes: [Anime]
        var pageInfo: PageInfo

        enum CodingKeys: String, CodingKey {
            case nodes
            case pageInfo
        }

        enum Arguments: String {
            case mediaType
            case first
            case last
            case before
            case after
        }

        enum MediaType: String, EnumValueRepresentable {
            case ANIME
            case MANGA
        }

        static var query: Weave {
            Weave(.query) {
                Object(GlobalTrending.self) {
                    Object(GlobalTrending.CodingKeys.nodes) {
                        Field(Anime.CodingKeys.id)
                        Field(Anime.CodingKeys.description)
                            .argument(key: Description.Argument.locales.rawValue, value: "en")
                        Object(Anime.CodingKeys.titles) {
                            Field(Titles.CodingKeys.preferred)
                            Field(Titles.CodingKeys.canonical)
                            Field(Titles.CodingKeys.alternatives)
                        }
                        Field(Anime.CodingKeys.slug)
                        Object(Anime.CodingKeys.posterImage) {
                            Object(Image.CodingKeys.original) {
                                Field(ImageView.CodingKeys.name)
                                Field(ImageView.CodingKeys.url)
                            }
                        }
                        Object(Anime.CodingKeys.bannerImage) {
                            Object(Image.CodingKeys.original) {
                                Field(ImageView.CodingKeys.name)
                                Field(ImageView.CodingKeys.url)
                            }
                        }
                    }
                    Object(GlobalTrending.CodingKeys.pageInfo) {
                        Field(PageInfo.CodingKeys.endCursor)
                        Field(PageInfo.CodingKeys.hasNextPage)
                        Field(PageInfo.CodingKeys.hasPreviousPage)
                        Field(PageInfo.CodingKeys.startCursor)

                    }
                }
                .argument(key: GlobalTrending.Arguments.mediaType.rawValue, value: GlobalTrending.MediaType.ANIME)
                .argument(key: GlobalTrending.Arguments.first.rawValue, value: 7)
            }
        }
    }

    // Models

    struct EpisodeConnection: Connection, Codable {
        var nodes: [Episode]
        var pageInfo: PageInfo

        enum CodingKeys: String, CodingKey {
            case nodes
            case pageInfo
        }
    }

    enum AgeRating: Codable {
        case G
        case PG
        case R
        case R18
    }

    struct Description: Codable {
        let en: String

        enum CodingKeys: String, CodingKey, CaseIterable {
            case en
        }

        enum Argument: String {
            case locales
        }
    }

    struct PageInfo: Codable {
        let endCursor: String?
        let hasNextPage: Bool
        let hasPreviousPage: Bool
        let startCursor: String?

        enum CodingKeys: String, CodingKey, CaseIterable {
            case endCursor
            case hasNextPage
            case hasPreviousPage
            case startCursor
        }
    }

    struct Episode: Codable {
        let anime: Anime
        let description: Description
        let id: String
        let length: Int
        let number: Int
        let thumbnail: Image?
        let titles: Titles

        enum CodingKeys: String, CodingKey, CaseIterable {
            case anime
            case description
            case id
            case length
            case number
            case thumbnail
            case titles
        }
    }

    struct Image: Codable {
        let blurHash: String?
        let original: ImageView
        let views: [ImageView]?

        enum CodingKeys: String, CodingKey, CaseIterable {
            case blurHash
            case original
            case views
        }
    }

    struct ImageView: Codable {
        let name, url: String
        let height, width: Int?

        enum CodingKeys: String, CodingKey, CaseIterable {
            case name
            case url
            case height
            case width
        }
    }

    struct Titles: Codable {
        let alternatives: [String]
        let canonical: String
        let original: String?
        let originalLocale: String?
        let preferred: String
        let romanizedLocale: String?
        let translated: String?
        let translatedLocale: String?

        enum CodingKeys: String, CodingKey, CaseIterable {
            case alternatives
            case canonical
            case original
            case originalLocale
            case preferred
            case romanizedLocale
            case translated
            case translatedLocale
        }
    }

    struct Anime: Media {
        // Media
        let id: String
        let description: Description
        let posterImage: Image?
        let bannerImage: Image?
        let titles: Titles
        let averageRating: Float?
        let averageRatingRank: Int?
        let slug: String

        // Anime Only

        let releaseSeason: ReleaseSeason?
        let youtubeTrailerVideoId: String?

        // Episodic

        let episodeCount: Int?
        let episodeLenght: Int?
        let episodes: EpisodeConnection?
        let totalLenght: Int?

        enum ReleaseSeason: Codable {
            case WINTER
            case SPRING
            case SUMMER
            case FALL
        }

        enum CodingKeys: String, CodingKey, CaseIterable {
            case id
            case description
            case posterImage
            case bannerImage
            case titles
            case averageRating
            case averageRatingRank
            case slug

            case releaseSeason
            case youtubeTrailerVideoId

            case episodeCount
            case episodeLenght
            case episodes
            case totalLenght
        }
    }
}
