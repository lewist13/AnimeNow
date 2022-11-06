////  CollectionStore.swift
//  Anime Now!
//
//  Created by ErrorErrorError on 10/28/22.
//  
//

import Foundation

struct CollectionStore: Equatable, Identifiable {
    var id = UUID()
    var title: String
    var lastUpdated = Date()
    var userRemovable = true
    var animes: [AnimeStore] = []

    var objectURL: URL?
}
