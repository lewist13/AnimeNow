//
//  EpisodeStore.swift
//  Anime Now!
//
//  Created by ErrorErrorError on 10/1/22.
//

import Foundation

public struct EpisodeStore: EpisodeRepresentable, Hashable, Codable, Identifiable {
    public var id = UUID()
    public var number: Int = 0
    public var title: String = ""
    public var thumbnail: ImageSize? = nil
    public var isFiller: Bool { false }
    public var links: Set<EpisodeLink> { [] }

    // Database Only

    public var progress: Double? = nil
    public var lastUpdatedProgress: Date = .init()

    public init(
        id: UUID = UUID(),
        number: Int = 0,
        title: String = "",
        thumbnail: ImageSize? = nil,
        progress: Double? = nil,
        lastUpdatedProgress: Date = .init()
    ) {
        self.id = id
        self.number = number
        self.title = title
        self.thumbnail = thumbnail
        self.progress = progress
        self.lastUpdatedProgress = lastUpdatedProgress
    }

    public init() {}
}

extension EpisodeStore {
    public static func findOrCreate(
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
    public var almostFinished: Bool {
        return (progress ?? 0) >= 0.9
    }

    public var finishedWatching: Bool {
        return (progress ?? 0) >= 1.0
    }
}
