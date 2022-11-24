//  AnimeStore+CoreData.swift
//  Anime Now!
//
//  Created by ErrorErrorError on 11/16/22.
//  

import SwiftORM
import Foundation

extension AnimeStore: ManagedObjectConvertible {
    static let entityName = "CDAnimeStore"

    static var idKeyPath: KeyPath = \Self.id

    static let attributes: Set<Attribute<AnimeStore>> = [
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
        (try? self.toData()) ?? .empty
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
        (try? self.toData()) ?? .empty
    }
}
