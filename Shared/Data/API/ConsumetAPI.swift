//
//  ConsumetAPI.swift
//  Anime Now! (iOS)
//
//  Created by Erik Bautista on 9/29/22.
//

import Foundation
import URLRouting

final class ConsumetAPI: APIRoute {
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

extension ConsumetAPI {
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

// MARK: - Converters

extension ConsumetAPI {
    static func convert(from sources: [ConsumetAPI.StreamingLink]) -> [AnimeNow.Source] {
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

    static func convert(from episodes: [ConsumetAPI.Episode]) -> [AnimeNow.Episode] {
        episodes.compactMap { episode in
            var thumbnailImages = [ImageSize]()

            if let thumbnailString = episode.image, let thumbnailURL = URL(string: thumbnailString) {
                thumbnailImages.append(.original(thumbnailURL))
            }

            return AnimeNow.Episode(
                id: episode.id,
                name: episode.title ?? "Untitled",
                number: episode.number,
                description: episode.description ?? "No description available for this episode.",
                thumbnail: thumbnailImages,
                length: nil
            )
        }
    }
}
