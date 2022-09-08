//
//  AnimeAPIProvider.swift
//  Anime Now! (iOS)
//
//  Created by Erik Bautista on 9/3/22.
//

import Foundation
import ComposableArchitecture

struct ListClient {
    let name: () -> AnimeLists
    let authenticate: () -> Effect<Void, Error>
    let trendingAnime: () -> Effect<[Anime], Error>
    let recentlyReleasedAnime: () -> Effect<[Anime], Error>
}

extension ListClient {
    enum AnimeLists: String {
        case kitsu
        case mock
    }
}
