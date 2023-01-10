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
        provider: String,
        fetchFiller: Bool = true
    ) -> Request<Route, [ConsumetAPI.Episode]> {
        .init(
            path: ["meta", "anilist", "episodes", animeId],
            query: [
                .init(name: "dub", dub),
                .init(name: "provider", provider.lowercased()),
                .init(name: "fetchFiller", fetchFiller)
            ]
        )
    }

    public static func anilistWatch(
        episodeId: String,
        dub: Bool,
        provider: String
    ) -> Request<Route, ConsumetAPI.StreamingLinksPayload> {
        .init(
            path: ["meta", "anilist", "watch", episodeId],
            query: [
                .init(name: "dub", dub),
                .init(name: "provider", provider),
            ]
        )
    }

    public static func listProviders(
        of type: ConsumetAPI.ProviderType = .ANIME
    ) -> Request<Route, [ProviderInfo]> {
        .init(
            path: ["utils", "providers"],
            query: [
                .init(name: "type", type.rawValue)
            ]
        )
    }
}

extension ConsumetAPI {
    public enum ProviderType: String {
        case ANIME
        case MANGA
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
        public let type: String?
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
        let isM3U8: Bool?
        let isDASH: Bool?
        let quality: String?
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

extension Source.Quality {
    fileprivate init?(
        _ quality: String
    ) {
        if let matched = Self.allCases.first(where: { $0.description.localizedCaseInsensitiveContains(quality) }) {
            self = matched
            return
        }

        if quality.localizedCaseInsensitiveContains("default") {
            self = .auto
            return
        } else if quality.localizedCaseInsensitiveContains("backup") {
            self = .autoalt
            return
        }
        return nil
    }
}

// MARK: - Converters

extension ConsumetAPI {
    public static func convert(from payload: StreamingLinksPayload) -> SharedModels.SourcesOptions {
        var sources: [SharedModels.Source] = []

        payload.sources.forEach { link in
            guard let quality = Source.Quality(link.quality ?? "default") else {
                return
            }

            guard let url = URL(string: link.url) else { return }

            if let source = sources.first(where: { $0.url.absoluteString == link.url }) {
                if source.quality <= quality {
                    sources.removeAll(where: { $0.url.absoluteString == link.url })
                } else {
                    return
                }
            }

            var format = Source.Format.m3u8

            if link.isDASH == true {
                format = .mpd
            }

            sources.append(
                .init(
                    url: url,
                    quality: quality,
                    format: format,
                    headers: payload.headers
                )
            )
        }

        let subtitles: [SharedModels.SourcesOptions.Subtitle] = (payload.subtitles ?? [])
            .compactMap { subtitle in
                guard let url = URL(string: subtitle.url),
                        subtitle.lang != "Thumbnails" else { return nil }
                return SharedModels.SourcesOptions.Subtitle(
                    url: url,
                    lang: subtitle.lang
                )
            }

        return .init(sources.sorted(by: \.quality), subtitles: subtitles)
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

        let title = (episode.title?.isEmpty ?? true) ? "Episode \(episode.number)" : episode.title ?? "Episode \(episode.number)"

        return SharedModels.Episode(
            title: title,
            number: episode.number,
            description: episode.description ?? "Description is not available for this episode.",
            thumbnail: thumbnail,
            isFiller: episode.isFiller ?? false
        )
    }
}
