//
//  SourceClient.swift
//  Anime Now!
//
//  Created by Erik Bautista on 9/12/22.
//

import Foundation
import ComposableArchitecture

struct SourceClient {
    let episodes: (Anime.ID) -> Effect<[Episode], API.Error>
    let sources: (Episode.ID) -> Effect<[Source], API.Error>
}
