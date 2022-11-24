//
//  EpisodeStore.swift
//  Anime Now!
//
//  Created by ErrorErrorError on 10/1/22.
//

import Foundation

struct EpisodeStore: EpisodeRepresentable, Hashable, Codable {
    var id = UUID()
    var number: Int = 0
    var title: String = ""
    var thumbnail: ImageSize? = nil
    var isFiller: Bool { false }

    // Database Only

    var isMovie: Bool = false
    var progress: Double = 0
    var lastUpdatedProgress: Date = .init()
    var downloadURL: URL? = nil
}

extension EpisodeStore {
    var providers: [Provider] {
        if let url = downloadURL {
            return [.offline(url: url)]
        } else {
            return []
        }
    }
}

extension EpisodeStore {
    var almostFinished: Bool {
        return progress >= 0.9
    }

    var finishedWatching: Bool {
        return progress >= 1.0
    }
}
