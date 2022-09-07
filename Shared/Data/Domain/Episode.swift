//
//  Episode.swift
//  Anime Now!
//
//  Created by Erik Bautista on 9/4/22.
//

import Foundation

struct EpisodeList {
    let episodes: [Episode]
    let nextPage: URL
}

struct Episode: Codable {
    let name: String
    let description: String
    let thumbnail: URL
    let length: Int
}
