//
//  Source.swift
//  Anime Now!
//
//  Created by ErrorErrorError on 9/12/22.
//

import Utilities
import Foundation

public struct Source: Hashable, Identifiable {
    public var id: URL { url }
    public let url: URL
    public let quality: Quality
    public let format: Format
    public let headers: [String: String]?

    public init(
        url: URL,
        quality: Source.Quality,
        format: Format = .m3u8,
        headers: [String: String]? = nil
    ) {
        self.url = url
        self.quality = quality
        self.headers = headers
        self.format = format
    }

    public enum Quality: Int, Hashable, Comparable, CustomStringConvertible, Codable, CaseIterable {
        public static func < (lhs: Source.Quality, rhs: Source.Quality) -> Bool {
            lhs.rawValue < rhs.rawValue
        }

        case onefourtyfourp = 0 // 144p
        case twoseventyp        // 270p
        case threesixtyp        // 360p
        case foureightyp        // 480p
        case seventwentyp       // 720p
        case teneightyp         // 1080p
        case autoalt            // auotoalt
        case auto               // auto

        public var description: String {
            switch self {
            case .auto:
                return "Auto"
            case .autoalt:
                return "Auto Alt"
            case .teneightyp:
                return "1080p"
            case .seventwentyp:
                return "720p"
            case .foureightyp:
                return "480p"
            case .threesixtyp:
                return "360p"
            case .twoseventyp:
                return "270p"
            case .onefourtyfourp:
                return "144p"
            }
        }
    }

    public enum Format: Hashable {
        /// HLS
        case m3u8

        /// DASH
        case mpd
    }
}

extension Source: CustomStringConvertible {
    public var description: String { quality.description }
}

extension Source {
    static let mock = [
        Source(
            url: URL(string: "/")!,
            quality: .auto
        )
    ]
}

public struct SourcesOptions: Hashable {
    public let sources: [Source]
    public let subtitles: [Subtitle]

    public init(
        _ sources: [Source],
        subtitles: [Subtitle] = []
    ) {
        self.sources = sources.sorted(by: \.quality).reversed()
        self.subtitles = subtitles
    }

    public struct Subtitle: Hashable, Identifiable {
        public var id: String { url.absoluteString }
        public let url: URL
        public let lang: String

        public init(
            url: URL,
            lang: String
        ) {
            self.url = url
            self.lang = lang
        }
    }
}
