//
//  AnimeStoredInfo.swift
//  Anime Now!
//
//  Created by Erik Bautista on 9/30/22.
//

import Foundation
import CoreData
import IdentifiedCollections

struct AnimeStoredInfo: Hashable, Codable, Identifiable {
    let id: Int64
    var isFavorite: Bool
    var episodesInfo: [EpisodeStoredInfo]
    var objectURL: URL?
}

extension AnimeStoredInfo {
    var lastModifiedEpisode: EpisodeStoredInfo? {
        episodesInfo.sorted(by: \.lastUpdatedProgress).last
    }
}
