//
//  Source.swift
//  Anime Now!
//
//  Created by ErrorErrorError on 9/12/22.
//

import Foundation

struct Source: Equatable, Identifiable {
    let id: String
    let url: URL
    let quality: Quality
    var sub: Bool? = nil          // not all providers have sub/dub, this is useful for zoro

    enum Quality: Int, Equatable, Comparable, CustomStringConvertible {
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
}

extension Source {
    static let mock = [
        Source(
            id: "",
            url: URL(string: "/")!,
            quality: .auto
        )
    ]
}
