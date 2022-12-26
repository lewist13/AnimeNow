//  AnimeStore+CoreData.swift
//  Anime Now!
//
//  Created by ErrorErrorError on 11/16/22.
//  

import Foundation
import SharedModels

extension AnimeStore: ManagedObjectConvertible {    
    public static let entityName = "CDAnimeStore"

    public static var idKeyPath: KeyPath = \Self.id

    public static let attributes: Set<Attribute<AnimeStore>> = [
        .init(\.id, "id"),
        .init(\.title, "title"),
        .init(\.posterImage, "posterImage"),
        .init(\.isFavorite, "isFavorite"),
        .init(\.format, "format"),
        .init(\.episodes, "episodeStores")
    ]
}

extension Array: ConvertableValue where Element: Codable {
    public func encode() -> Data {
        (try? self.toData()) ?? .init()
    }

    public static func decode(value: Data) throws -> Self {
        try value.toObject()
    }
}

extension Anime.Format: ConvertableValue {
    public static func decode(value: Data) throws -> Self {
        try value.toObject()
    }

    public func encode() -> Data {
        (try? self.toData()) ?? .init()
    }
}
