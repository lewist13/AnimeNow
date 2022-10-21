//
//  AnimeStore.swift
//  Anime Now!
//
//  Created by ErrorErrorError on 9/30/22.
//

import Foundation
import CoreData
import IdentifiedCollections

struct AnimeStore: AnimeRepresentable, Codable, Equatable, Identifiable {
    let id: Anime.ID
    var title: String
    var malId: Int? { nil }
    var format: Anime.Format
    var posterImage: [ImageSize]

    var isFavorite: Bool
    var inWatchlist: Bool
    var episodeStores: [EpisodeStore]

    var objectURL: URL?
}

extension AnimeStore {
    var lastModifiedEpisode: EpisodeStore? {
        episodeStores.sorted(by: \.lastUpdatedProgress).last
    }
}

extension AnimeStore {
    static func findOrCreate(
        _ anime: AnimeRepresentable,
        _ animeStores: [AnimeStore] = []
    ) -> AnimeStore {
        if var animeStoreItem = animeStores.first(where: { $0.id == anime.id }) {
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
                isFavorite: false,
                inWatchlist: false,
                episodeStores: .init()
            )
        }
    }
}

extension AnimeStore {
    mutating func updateProgress(
        for episode: EpisodeRepresentable,
        anime: AnimeRepresentable,
        progress: Double
    ) {
        guard anime.id == id else { return }

        var episodeStoredInfo: EpisodeStore = episodeStores.first(where: { $0.number == episode.number }) ?? .init(
            number: episode.number,
            title: anime.format == .movie ? anime.title : episode.title,
            thumbnail: anime.format == .movie ? anime.posterImage.largest : episode.thumbnail,
            isMovie: anime.format == .movie,
            progress: progress,
            lastUpdatedProgress: .init()
        )

        episodeStoredInfo.number = episode.number
        episodeStoredInfo.title = anime.format == .movie ? anime.title : episode.title
        episodeStoredInfo.thumbnail = anime.format == .movie ? anime.posterImage.largest :  episode.thumbnail
        episodeStoredInfo.isMovie = anime.format == .movie
        episodeStoredInfo.progress = progress
        episodeStoredInfo.lastUpdatedProgress = .init()

        episodeStores.insertOrUpdate(episodeStoredInfo)
    }
}
