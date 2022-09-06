//
//  Anime.swift
//  Anime Now! (macOS)
//
//  Created by Erik Bautista on 9/4/22.
//

import Foundation

struct Anime: Hashable {
    let id: String
    let title: String
    let description: String
    let posterImage: URL
    let coverImage: URL
}
