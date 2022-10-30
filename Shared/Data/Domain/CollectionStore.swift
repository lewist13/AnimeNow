////  CollectionStore.swift
//  Anime Now!
//
//  Created by ErrorErrorError on 10/28/22.
//  
//

import Foundation

struct CollectionStore: Equatable, Identifiable {
    let id: UUID
    var animes: [AnimeStore]
    var name: String
    var lastUpdated: Date
    var objectURL: URL?
}
