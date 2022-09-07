//
//  AnimeAPIProvider.swift
//  Anime Now! (iOS)
//
//  Created by Erik Bautista on 9/3/22.
//

import Foundation
import ComposableArchitecture
import Parsing
import URLRouting

struct ListClient {
    let name: () -> AnimeLists
    let authenticate: () -> Effect<Void, Error>
    let trendingAnime: () -> Effect<[Anime], Error>
}

extension ListClient {
    enum AnimeLists: String {
        case kitsu
        case mock
    }
}
