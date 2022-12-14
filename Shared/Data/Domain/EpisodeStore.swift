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
    var providers: [Provider] { [] }

    // Database Only

    var progress: Double? = nil
    var lastUpdatedProgress: Date = .init()
}

extension EpisodeStore {
    static func findOrCreate(
        _ episode: any EpisodeRepresentable,
        _ episodes: Set<EpisodeStore>
    ) -> EpisodeStore {
        if let episodeFound = episodes.first(where: { $0.number == episode.number }) {
            return episodeFound
        } else {
            return .init(
                number: episode.number,
                title: episode.title,
                thumbnail: episode.thumbnail,
                lastUpdatedProgress: .init()
            )
        }
    }
}

extension EpisodeStore {
    var almostFinished: Bool {
        return (progress ?? 0) >= 0.9
    }

    var finishedWatching: Bool {
        return (progress ?? 0) >= 1.0
    }
}
