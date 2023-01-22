//
//  File.swift
//  
//
//  Created by ErrorErrorError on 1/18/23.
//  
//

import Foundation

public struct UpdatedAnimeEpisode: Equatable {
    public init(
        anime: Anime,
        episode: Episode
    ) {
        self.anime = anime
        self.episode = episode
    }

    public let anime: Anime
    public let episode: Episode
}
