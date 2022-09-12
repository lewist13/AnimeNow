//
//  AnimeListClient+Enime.swift
//  Anime Now!
//
//  Created by Erik Bautista on 9/11/22.
//

import Foundation
import ComposableArchitecture
import URLRouting

extension AnimeListClient {
    static let enime: Self = {
        let route = EnimeRoute()

        return AnimeListClient {
            .none
        } topTrendingAnime: {
            .init(value: [])
        } topUpcomingAnime: {
            .init(value: [])
        } topAiringAnime: {
            .init(value: [])
        } highestRatedAnime: {
            .init(value: [])
        } mostPopularAnime: {
            let endpoint = EnimeRoute.Endpoint.popular
            let response = API.request(route, endpoint, DataResponse<Anime>.self)

            return response
                .map { $0?.data ?? [] }
                .map(convertEnimeAnimeToAnime(enimes:))
                .eraseToEffect()
        } episodes: { animeId in
            if case let .enime(enimeId) = animeId {
                let endpoint = EnimeRoute.Endpoint.fetchEpisodes(animeId: enimeId)
                let response = API.request(route, endpoint, [Episode].self)
                return response
                    .map { $0 ?? [] }
                    .map(convertEnimeEpisodeToEpisode(episodes:))
                    .eraseToEffect()
            } else {
                return .init(value: [])
            }
        }
    }()
}

private func convertEnimeEpisodeToEpisode(episodes: [AnimeListClient.Episode]) -> [Episode] {
    episodes.compactMap { episode in
        var thumbainImages = [Anime.Image]()

        if let thumbnailString = episode.image, let thumbnailURL = URL(string: thumbnailString) {
            thumbainImages.append(.original(thumbnailURL))
        }

        return Episode(
            id: episode.id,
            name: episode.title ?? "Episode \(episode.number)",
            number: episode.number,
            description: episode.description ?? "No description available for this episode.",
            thumbnail: thumbainImages,
            length: nil
        )
    }
}

private func convertEnimeAnimeToAnime(enimes: [AnimeListClient.Anime]) -> [Anime] {
    enimes.compactMap { enime in
        guard enime.format != .MUSIC else { return nil }

        var posterImages = [Anime.Image]()
        var coverImages = [Anime.Image]()

        if let posterImageURL = URL(string: enime.coverImage) {
            posterImages.append(.original(posterImageURL))
        }

        if let coverImageStr = enime.bannerImage,
           let coverImageURL = URL(string: coverImageStr) {
            coverImages.append(.original(coverImageURL))
        }

        var status: Anime.Status = .current

        switch enime.status {
        case .RELEASING:
            status = .current
        case .FINISHED:
            status = .finished
        case .CANCELLED:
            status = .finished
        case .HIATUS:
            status = .current
        case .NOTYETRELEASED:
            status = .unreleased
        }

        let format: Anime.Format

        switch enime.format {
        case .MOVIE:
            format = .movie
        default:
            format = .show
        }

        return Anime(
            id: .enime(enime.id),
            title: enime.title.english ?? enime.title.romaji ?? enime.title.native ?? "Untitled",
            description: enime.description.trimHTMLTags() ?? "Description not available for this anime.",
            posterImage: posterImages,
            coverImage: coverImages,
            categories: enime.genre,
            status: status,
            format: format
        )
    }
}

fileprivate extension AnimeListClient {
    class EnimeRoute: APIRoute {
        enum Endpoint: Equatable {
            case anime(id: String)
            case mapping(ExternalProvider)
            case fetchEpisodes(animeId: String)
            case recentEpisodes
            case search(query: String, all: Bool = false, params: PageSize = .init())
            case popular

            struct ExternalProvider: Equatable, Decodable {
                var provider: Provider
                var id: String

                enum Provider: String, CaseIterable, Equatable, Decodable {
                    case kitsu
                    case anidm
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
                Route(.case(Endpoint.popular)) {
                    Path { "popular" }
                }
                Route(.case(Endpoint.anime(id:))) {
                    Path { "anime"; Parse(.string) }
                }
                Route(.case(Endpoint.mapping)) {
                    Path {
                        "mapping"
                    }
                    Parse(.memberwise(Endpoint.ExternalProvider.init)) {
                        Path { Endpoint.ExternalProvider.Provider.parser(); Parse(.string) }
                    }
                }
                Route(.case(Endpoint.fetchEpisodes(animeId:))) {
                    Path { "anime"; Parse(.string); "episodes" }
                }
                Route(.case(Endpoint.recentEpisodes)) {
                    Path { "recent" }
                }
                Route(.case(Endpoint.search(query:all:params:))) {
                    Path { "search"; Parse(.string) }
                    Query {
                        Field("all", default: false) { Bool.parser() }
                    }
                    Parse(.memberwise(Endpoint.PageSize.init)) {
                        Query {
                            Field.init("page", default: 1) { Int.parser() }
                            Field("perPage", default: 10) { Int.parser() }
                        }
                    }
                }
            }
            .eraseToAnyParserPrinter()
        }()

        let baseURL = URL(string: "https://api.enime.moe")!

        func applyHeaders(request: inout URLRequest) {
        }
    }
}

fileprivate extension AnimeListClient {
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

    // MARK: - Anime
    struct Anime: Decodable {
        let id: String
//        let slug: String
//        let anilistId: Int
        let coverImage: String
        let bannerImage: String?
        let status: Status
        let format: Format
//        let season: Season
        let year: Int
        let title: Title
//        let currentEpisode: Int
//        let next: String
//        let synonyms: [String]
//        let lastEpisodeUpdate: String
        let description: String
//        let duration: Int
        let averageScore: Int
        let popularity: Int
//        let color: String
//        let mappings: Mappings
        let genre: [String]
//        let episodes: [Episode]
//        let relations: [Relation]

        enum Status: String, Decodable {
            case RELEASING
            case FINISHED
            case CANCELLED
            case HIATUS
            case NOTYETRELEASED = "NOT_YET_RELEASED"
        }

        enum Format: String, Decodable {
            case TV
            case UNKNOWN
            case TV_SHORT
            case MOVIE
            case SPECIAL
            case OVA
            case ONA
            case MUSIC
        }

        enum Season: String, Decodable {
            case SUMMER
            case WINTER
            case FALL
            case SPRING
        }
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

    // MARK: - Relation
    struct Relation: Decodable {
        let anime: Anime
        let type: String
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
