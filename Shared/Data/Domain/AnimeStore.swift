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
        if var animeStoreItem = animeStores[id: anime.id] {
            animeStoreItem.title = anime.title
            animeStoreItem.format = anime.format
            animeStoreItem.posterImage = anime.posterImage
            return animeStoreItem
        } else {
            return .init(
                id: anime.id,
                title: anime.title,
                format: anime.format,
                posterImage: anime.posterImage,
                isFavorite: false
            )
        }
    }
}

extension AnimeStore {
    mutating func updateProgress(
        for episode: any EpisodeRepresentable,
        progress: Double
    ) {

        var episodeInfo = episodes.first(where: { $0.number == episode.number }) ?? .init(
            number: episode.number,
            title: format == .movie ? title : episode.title,
            thumbnail: format == .movie ? posterImage.largest : episode.thumbnail,
            isMovie: format == .movie,
            progress: progress,
            lastUpdatedProgress: .init()
        )

        episodeInfo.number = episode.number
        episodeInfo.title = format == .movie ? title : episode.title
        episodeInfo.thumbnail = format == .movie ? posterImage.largest :  episode.thumbnail
        episodeInfo.isMovie = format == .movie
        episodeInfo.progress = progress
        episodeInfo.lastUpdatedProgress = .init()

        episodes.update(episodeInfo)
    }
}
