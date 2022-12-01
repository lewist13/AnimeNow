//
//  AnimeStore.swift
//  Anime Now!
//
//  Created by ErrorErrorError on 9/30/22.
//

import Foundation
import CoreData
import IdentifiedCollections

struct AnimeStore: AnimeRepresentable {
    var id: Anime.ID = .init()
    var title: String = ""
    var malId: Int? { nil }
    var format = Anime.Format.tv
    var posterImage: [ImageSize] = []
    var isFavorite = false

    var episodes = Set<EpisodeStore>()
}

extension AnimeStore {
    var lastModifiedEpisode: EpisodeStore? {
        episodes.sorted(by: \.lastUpdatedProgress).last
    }
}

extension AnimeStore {
    static func findOrCreate(
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
    mutating func updateProgress(
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
