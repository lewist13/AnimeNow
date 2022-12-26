//
//  AnimeStore.swift
//  Anime Now!
//
//  Created by ErrorErrorError on 9/30/22.
//

import Utilities
import Foundation
import IdentifiedCollections

public struct AnimeStore: AnimeRepresentable {
    public var id: Anime.ID = .init()
    public var title: String = ""
    public var malId: Int? { nil }
    public var format = Anime.Format.tv
    public var posterImage: [ImageSize] = []
    public var isFavorite = false

    public var episodes = Set<EpisodeStore>()

    public init(
        id: Anime.ID = .init(),
        title: String = "",
        format: Anime.Format = Anime.Format.tv,
        posterImage: [ImageSize] = [],
        isFavorite: Bool = false,
        episodes: Set<EpisodeStore> = Set<EpisodeStore>()
    ) {
        self.id = id
        self.title = title
        self.format = format
        self.posterImage = posterImage
        self.isFavorite = isFavorite
        self.episodes = episodes
    }

    public init() {  }
}

extension AnimeStore {
    public var lastModifiedEpisode: EpisodeStore? {
        episodes.sorted(by: \.lastUpdatedProgress).last
    }
}

extension AnimeStore {
    public static func findOrCreate(
        _ anime: any AnimeRepresentable,
        _ animeStores: [AnimeStore] = []
    ) -> AnimeStore {
        var animeStoreItem = animeStores[id: anime.id] ?? .init(id: anime.id)
        animeStoreItem.title = anime.title
        animeStoreItem.format = anime.format
        animeStoreItem.posterImage = anime.posterImage
        return animeStoreItem
    }
}

extension AnimeStore {
    public mutating func updateProgress(
        for episode: any EpisodeRepresentable,
        progress: Double
    ) {
        var episodeInfo = EpisodeStore.findOrCreate(episode, episodes)

        episodeInfo.number = episode.number
        episodeInfo.title = format == .movie ? title : episode.title
        episodeInfo.thumbnail = format == .movie ? posterImage.largest :  episode.thumbnail
        episodeInfo.progress = progress
        episodeInfo.lastUpdatedProgress = .init()

        episodes.update(episodeInfo)
    }
}
