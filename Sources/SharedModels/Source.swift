//
//  Source.swift
//  Anime Now!
//
//  Created by ErrorErrorError on 9/12/22.
//

import Utilities
import Foundation

public struct Source: Hashable, Identifiable {
    public let id: Int
    public let url: URL
    public let quality: Quality

    public init(
        id: Int,
        url: URL,
        quality: Source.Quality
    ) {
        self.id = id
        self.url = url
        self.quality = quality
    }

    public enum Quality: Int, Hashable, Comparable, CustomStringConvertible, Codable {
        public static func < (lhs: Source.Quality, rhs: Source.Quality) -> Bool {
            lhs.rawValue < rhs.rawValue
        }

        case onefourtyfourp = 0 // 144p
        case twoseventyp        // 270p
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
            case .twoseventyp:
                return "270p"
            case .onefourtyfourp:
                return "144p"
            }
        }
    }

    public struct Subtitle: Hashable, Identifiable {
        public let id: Int
        public let url: URL
        public let lang: String

        public init(
            id: Int,
            url: URL,
            lang: String
        ) {
            self.id = id
            self.url = url
            self.lang = lang
        }
    }
}

extension Source {
    static let mock = [
        Source(
            id: 0,
            url: URL(string: "/")!,
            quality: .auto
        )
    ]
}

public struct SourcesOptions: Hashable {
    public let sources: [Source]
    public let subtitles: [Source.Subtitle]

    public init(
        _ sources: [Source],
        subtitles: [Source.Subtitle] = []
    ) {
        self.sources = sources.sorted(by: \.quality).reversed()
        self.subtitles = subtitles
    }
}
