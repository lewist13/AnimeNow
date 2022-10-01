//
//  EpisodeStoredInfo.swift
//  Anime Now!
//
//  Created by Erik Bautista on 10/1/22.
//

import Foundation

struct EpisodeStoredInfo: Hashable, Codable, Identifiable {
    var id: Int16 { number }
    let number: Int16
    let title: String
    let cover: ImageSize?
    var isMovie: Bool
    var progress: Double
    var lastUpdatedProgress: Date
    var downloadURL: URL?
}

extension EpisodeStoredInfo {
    var finishedWatching: Bool {
        return progress >= 0.9
    }
}
