//
//  EpisodeSource.swift
//  Anime Now!
//
//  Created by Erik Bautista on 9/12/22.
//

import Foundation

struct EpisodeSource: Equatable {
    let id: String
    let url: URL
    let provider: String
    let subbed: Bool
}

extension EpisodeSource {
    static let mock = [
        EpisodeSource(
            id: "",
            url: URL(string: "/")!,
            provider: "",
            subbed: false
        )
    ]
}
