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

struct AnimeListClient {
    let name: () -> String
    let authenticate: () -> Void
    let trendingAnime: () -> Effect<[Anime], Error>
}

extension AnimeListClient {
}
