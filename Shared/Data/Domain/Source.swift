//
//  Source.swift
//  Anime Now!
//
//  Created by ErrorErrorError on 9/12/22.
//

import Foundation

struct Source: Hashable, Identifiable {
    let id: Int
    let url: URL
    let quality: Quality

    enum Quality: Int, Hashable, Comparable, CustomStringConvertible, Codable {
        static func < (lhs: Source.Quality, rhs: Source.Quality) -> Bool {
            lhs.rawValue < rhs.rawValue
        }

        case onefourtyfourp = 0 // 144p
        case twoseventyp        // 270p
        case foureightyp        // 480p
        case seventwentyp       // 720p
        case teneightyp         // 1080p
        case autoalt            // auotoalt
        case auto               // auto

        var description: String {
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

    struct Subtitle: Hashable, Identifiable {
        let id: Int
        let url: URL
        let lang: String
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

struct SourcesOptions: Hashable {
    public let sources: [Source]
    public let subtitles: [Source.Subtitle]

    init(
        _ sources: [Source],
        subtitles: [Source.Subtitle] = []
    ) {
        self.sources = sources.sorted(by: \.quality).reversed()
        self.subtitles = subtitles
    }
}
