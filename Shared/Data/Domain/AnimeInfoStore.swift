//
//  AnimeInfoStore.swift
//  Anime Now!
//
//  Created by Erik Bautista on 9/30/22.
//

import Foundation
import CoreData
import IdentifiedCollections

struct AnimeInfoStore: Hashable, Codable, Identifiable {
    let id: Anime.ID
    var isFavorite: Bool
    var episodesInfo: [EpisodeInfoStore]
    var objectURL: URL?
}

extension AnimeInfoStore {
    var lastModifiedEpisode: EpisodeInfoStore? {
        episodesInfo.sorted(by: \.lastUpdatedProgress).last
    }
}

extension AnimeInfoStore {
    mutating func updateProgress(for episode: Episode, anime: Anime, progress: Double) {
        guard anime.id == id else { return }

        var episodeStoredInfo: EpisodeInfoStore = episodesInfo.first(where: { $0.number == episode.number }) ?? .init(
            number: Int16(episode.number),
            title: anime.format == .movie ? anime.title : episode.name,
            cover: anime.format == .movie ? anime.posterImage.largest :  episode.thumbnail.first,
            isMovie: anime.format == .movie,
            progress: progress,
            lastUpdatedProgress: .init()
        )

        episodeStoredInfo.progress = progress

        episodesInfo.insertOrUpdate(episodeStoredInfo)
    }
}
