//
//  AnimeDBModel.swift
//  Anime Now!
//
//  Created by Erik Bautista on 9/30/22.
//

import Foundation
import CoreData
import IdentifiedCollections

struct AnimeDBModel: Hashable, Codable, Identifiable {
    let id: Int64
    var isFavorite: Bool
    var progressInfos: [ProgressInfo]
    var objectURL: URL?
}
