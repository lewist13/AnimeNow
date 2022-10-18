//
//  EpisodeStore.swift
//  Anime Now!
//
//  Created by ErrorErrorError on 10/1/22.
//

import Foundation

struct EpisodeStore: Hashable, Codable, Identifiable {
    var id = UUID()
    var number: Int16
    var title: String
    var cover: ImageSize?
    var isMovie: Bool
    var progress: Double
    var lastUpdatedProgress: Date
    var downloadURL: URL?

    var objectURL: URL?
}

extension EpisodeStore {
    var almostFinished: Bool {
        return progress >= 0.9
    }

    var finishedWatching: Bool {
        return progress >= 1.0
    }
}
