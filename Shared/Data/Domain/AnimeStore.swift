//
//  AnimeStore.swift
//  Anime Now!
//
//  Created by Erik Bautista on 9/30/22.
//

import Foundation
import CoreData
import IdentifiedCollections

struct AnimeStore: Hashable, Codable, Identifiable {
    let id: Anime.ID
    var isFavorite: Bool
    var episodeStores: [EpisodeStore]
    var objectURL: URL?
}

extension AnimeStore {
    var lastModifiedEpisode: EpisodeStore? {
        episodeStores.sorted(by: \.lastUpdatedProgress).last
    }
}

extension AnimeStore {
    static func findOrCreate(_ id: Anime.ID, _ animes: [AnimeStore] = []) -> AnimeStore {
        if let anime = animes.first(where: { $0.id == id }) {
            return anime
        } else {
            return .init(
                id: id,
                isFavorite: false,
                episodeStores: .init()
            )
        }
    }
}

extension AnimeStore {
    mutating func updateProgress(for episode: Episode, anime: Anime, progress: Double) {
        guard anime.id == id else { return }

        var episodeStoredInfo: EpisodeStore = episodeStores.first(where: { $0.number == episode.number }) ?? .init(
            number: Int16(episode.number),
            title: anime.format == .movie ? anime.title : episode.name,
            cover: anime.format == .movie ? anime.posterImage.largest :  episode.thumbnail.first,
            isMovie: anime.format == .movie,
            progress: progress,
            lastUpdatedProgress: .init()
        )

        episodeStoredInfo.number = Int16(episode.number)
        episodeStoredInfo.title = anime.format == .movie ? anime.title : episode.name
        episodeStoredInfo.cover = anime.format == .movie ? anime.posterImage.largest :  episode.thumbnail.first
        episodeStoredInfo.isMovie = anime.format == .movie
        episodeStoredInfo.progress = progress
        episodeStoredInfo.lastUpdatedProgress = .init()

        episodeStores.insertOrUpdate(episodeStoredInfo)
    }
}
