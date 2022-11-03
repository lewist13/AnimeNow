//
//  ConsumetAPI.swift
//  Anime Now! (iOS)
//
//  Created by ErrorErrorError on 9/29/22.
//

import Foundation
import URLRouting

final class ConsumetAPI: APIRoutable {
    enum Endpoint: Equatable {
        case anilist(AnilistEndpoint)
        case enime(EnimeEndpoint)

        enum EnimeEndpoint: Equatable {
            case watch(episodeId: String)
            case query(String)
            case info(animeId: String)
        }

        enum AnilistEndpoint: Equatable {
            case animeInfo(animeId: Int, options: EpisodeInfo)
            case episodes(animeId: Int, options: EpisodeInfo)
            case watch(episodeId: String, options: WatchInfo)

            struct EpisodeInfo: Equatable {
                var dub: Bool = false
                var provider: Provider = .gogoanime
                var fetchFiller = false
            }

            struct WatchInfo: Equatable {
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
                        Parse(.memberwise(Endpoint.AnilistEndpoint.EpisodeInfo.init(dub:provider:fetchFiller:))) {
                            Query {
                                Field("dub") { Bool.parser() }
                                Field("provider") { Endpoint.AnilistEndpoint.Provider.parser() }
                                Field("fetchFiller") { Bool.parser() }
                            }
                        }
                    }
                    Route(.case(Endpoint.AnilistEndpoint.episodes(animeId:options:))) {
                        Path { "episodes"; Int.parser() }
                        Parse(.memberwise(Endpoint.AnilistEndpoint.EpisodeInfo.init(dub:provider:fetchFiller:))) {
                            Query {
                                Field("dub") { Bool.parser() }
                                Field("provider") { Endpoint.AnilistEndpoint.Provider.parser() }
                                Field("fetchFiller") { Bool.parser() }
                            }
                        }
                    }
                    Route(.case(Endpoint.AnilistEndpoint.watch(episodeId:options:))) {
                        Path { "watch"; Parse(.string) }
                        Parse(.memberwise(Endpoint.AnilistEndpoint.WatchInfo.init(dub:provider:))) {
                            Query {
                                Field("dub") { Bool.parser() }
                                Field("provider") { Endpoint.AnilistEndpoint.Provider.parser() }
                            }
                        }
                    }
                }
            }
        }
        .eraseToAnyParserPrinter()
    }()

    func configureRequest(request: inout URLRequest) {}
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
        let isFiller: Bool?
    }

    struct StreamingLinksPayload: Decodable {
        let sources: [StreamingLink]
        let subtitles: [Subtitle]?
        let intro: Intro?
        let headers: [String: String]?
    }

    struct StreamingLink: Decodable {
        let url: String
        let isM3U8: Bool
        let quality: String
    }

    struct Subtitle: Decodable {
        let url: String
        let lang: String
    }

    struct Intro: Decodable {
        let start: Int
        let end: Int
    }
}

// MARK: - Converters

extension ConsumetAPI {
    static func convert(from payload: StreamingLinksPayload) -> AnimeNow.SourcesOptions {
        let sources: [AnimeNow.Source] = zip(payload.sources.indices, payload.sources)
            .compactMap { (index, streamingLink) in
                let quality: Source.Quality

                if streamingLink.quality == "default" {
                    quality = .auto
                } else if streamingLink.quality == "backup" {
                    quality = .autoalt
                } else if streamingLink.quality == "1080p" {
                    quality = .teneightyp
                } else if streamingLink.quality == "720p" {
                    quality = .seventwentyp
                } else if streamingLink.quality == "480p" {
                    quality = .foureightyp
                } else if streamingLink.quality == "270p" {
                    quality = .twoseventyp
                } else if streamingLink.quality == "144p" {
                    quality = .onefourtyfourp
                } else {
                    quality = .autoalt
                }

                guard let url = URL(string: streamingLink.url) else { return nil }

                return AnimeNow.Source(
                    id: index,
                    url: url,
                    quality: quality
                )
            }

        let subtitles: [AnimeNow.Source.Subtitle] = payload.subtitles?.enumerated().compactMap({ index, subtitle in
            guard let url = URL(string: subtitle.url), subtitle.lang != "Thumbnails" else { return nil }
            return AnimeNow.Source.Subtitle(
                id: index,
                url: url,
                lang: subtitle.lang
            )
        }) ?? []
        return .init(sources, subtitles: subtitles)
    }

    static func convert(from episodes: [ConsumetAPI.Episode]) -> [AnimeNow.Episode] {
        episodes.compactMap(convert(from:))
    }

    static func convert(from episode: ConsumetAPI.Episode) -> AnimeNow.Episode {
        let thumbnail: ImageSize?

        if let thumbnailString = episode.image, let thumbnailURL = URL(string: thumbnailString) {
            thumbnail = .original(thumbnailURL)
        } else {
            thumbnail = nil
        }

        return AnimeNow.Episode(
            title: episode.title ?? "Untitled",
            number: episode.number,
            description: episode.description ?? "No description available for this episode.",
            thumbnail: thumbnail,
            isFiller: episode.isFiller ?? false
        )
    }
}
