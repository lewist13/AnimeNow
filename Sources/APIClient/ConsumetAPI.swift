//
//  ConsumetAPI.swift
//  Anime Now! (iOS)
//
//  Created by ErrorErrorError on 9/29/22.
//

import Foundation
import SharedModels

public final class ConsumetAPI: APIBase {
    public static let shared: ConsumetAPI = .init()

    public let base = URL(string: "https://api.consumet.org")!

    private init() { }
}

extension Request where Route == ConsumetAPI {
    public static func anilistEpisodes(
        animeId: Int,
        dub: Bool,
        provider: ConsumetAPI.Provider,
        fetchFiller: Bool = false
    ) -> Request<Route, [ConsumetAPI.Episode]> {
        .init(
            path: ["meta", "anilist", "episodes", animeId],
            query: [
                .init(name: "dub", value: dub),
                .init(name: "provider", value: provider.rawValue),
                .init(name: "fetchFiller", value: fetchFiller)
            ]
        )
    }

    public static func anilistWatch(
        episodeId: String,
        dub: Bool,
        provider: ConsumetAPI.Provider
    ) -> Request<Route, ConsumetAPI.StreamingLinksPayload> {
        .init(
            path: ["meta", "anilist", "watch", episodeId],
            query: [
                .init(name: "dub", value: dub),
                .init(name: "provider", value: provider.rawValue),
            ]
        )
    }
}

extension ConsumetAPI {
    public enum Provider: String, CaseIterable, Decodable {
        case gogoanime
        case zoro
    }

    public struct Anime: Equatable, Decodable {
        let id: String
        let subOrDub: AudioType
        let episodes: [Episode]

        enum AudioType: String, Equatable, Decodable {
            case sub, dub
        }
    }

    public struct Episode: Equatable, Decodable {
        public let id: String
        public let number: Int
        public let title: String?
        public let image: String?
        public let description: String?
        public let isFiller: Bool?
    }

    public struct StreamingLinksPayload: Decodable {
        let sources: [StreamingLink]
        let subtitles: [Subtitle]?
        let intro: Intro?
        let headers: [String: String]?
    }

    public struct StreamingLink: Decodable {
        let url: String
        let isM3U8: Bool
        let quality: String
    }

    public struct Subtitle: Decodable {
        let url: String
        let lang: String
    }

    public struct Intro: Decodable {
        let start: Int
        let end: Int
    }
}

// MARK: - Converters

extension ConsumetAPI {
    public static func convert(from payload: StreamingLinksPayload) -> SharedModels.SourcesOptions {
        let sources: [SharedModels.Source] = zip(payload.sources.indices, payload.sources)
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

                return SharedModels.Source(
                    id: index,
                    url: url,
                    quality: quality
                )
            }

        let subtitles: [SharedModels.Source.Subtitle] = payload.subtitles?.enumerated().compactMap({ index, subtitle in
            guard let url = URL(string: subtitle.url), subtitle.lang != "Thumbnails" else { return nil }
            return SharedModels.Source.Subtitle(
                id: index,
                url: url,
                lang: subtitle.lang
            )
        }) ?? []
        return .init(sources, subtitles: subtitles)
    }

    public static func convert(from episodes: [ConsumetAPI.Episode]) -> [SharedModels.Episode] {
        episodes.compactMap(convert(from:))
    }

    public static func convert(from episode: ConsumetAPI.Episode) -> SharedModels.Episode {
        let thumbnail: ImageSize?

        if let thumbnailString = episode.image, let thumbnailURL = URL(string: thumbnailString) {
            thumbnail = .original(thumbnailURL)
        } else {
            thumbnail = nil
        }

        return SharedModels.Episode(
            title: episode.title ?? "Untitled",
            number: episode.number,
            description: episode.description ?? "No description available for this episode.",
            thumbnail: thumbnail,
            isFiller: episode.isFiller ?? false
        )
    }
}
