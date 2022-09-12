//
//  Episode.swift
//  Anime Now!
//
//  Created by Erik Bautista on 9/4/22.
//

import Foundation

struct EpisodeList {
    let episodes: [Episode]
    let nextPage: URL
}

struct Episode: Equatable, Identifiable {
    let id: String
    let name: String
    let number: Int
    let description: String
    let thumbnail: [Anime.Image]
    let length: Int?                 // Seconds
}

extension Episode {
    var lengthFormatted: String {
        guard let length = length else { return "" }
        let hours = length / 3600
        let minutes = (length % 3600) / 60
        let seconds = (length % 3600) % 60

        var retVal: [String] = []

        if hours > 0 {
            retVal += ["\(hours) h"]
        }

        if minutes > 0 {
            retVal += ["\(minutes) m"]
        }

        if seconds > 0 && minutes == 0 {
            retVal += ["\(seconds) s"]
        }

        return retVal.joined(separator: " ")
    }
}

extension Episode {
    static let empty = Episode(
        id: "",
        name: "",
        number: 0,
        description: "",
        thumbnail: [],
        length: 0
    )

    static let demoEpisodes: [Episode] = [
        .init(
            id: "1",
            name: "Test 1",
            number: 0,
            description: "Helloooooo guesss what??",
            thumbnail: [],
            length: 1250
        )
    ]
}
