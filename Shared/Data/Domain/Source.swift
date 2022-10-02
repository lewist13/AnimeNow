//
//  Source.swift
//  Anime Now!
//
//  Created by Erik Bautista on 9/12/22.
//

import Foundation

struct Source: Equatable, Identifiable {
    let id: String
    let url: URL
    let provider: Provider
    let subbed: Bool
    let quality: Quality

    enum Quality {
        case auto           // auto
        case autoalt        // auotoalt
        case teneightyp     // 1080p
        case seventwentyp   // 720p
        case foureightyp    // 480p
        case twoseventyp    // 270p
        case onefourtyfourp // 144p

        var stringify: String {
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
            provider: .gogoanime,
            subbed: false,
            quality: .auto
        )
    ]

    enum Provider {
        case gogoanime
        case zoro
    }
}
