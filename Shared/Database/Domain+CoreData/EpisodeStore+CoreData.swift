//  EpisodeStore+CoreData.swift
//  Anime Now!
//
//  Created by ErrorErrorError on 11/16/22.
//  

import SwiftORM
import Foundation

extension EpisodeStore: ManagedObjectConvertible {
    static let entityName = "CDEpisodeStore"

    static var idKeyPath: KeyPath = \Self.id

    static let attributes: Set<Attribute<EpisodeStore>> = [
        .init(\.id, "id"),
        .init(\.number, "number"),
        .init(\.title, "title"),
        .init(\.thumbnail, "cover"),
        .init(\.isMovie, "isMovie"),
        .init(\.progress, "progress"),
        .init(\.lastUpdatedProgress, "lastUpdatedProgress"),
        .init(\.downloadURL, "downloadURL")
    ]
}

extension ImageSize: ConvertableValue {
    public static func decode(value primitiveValue: Data) throws -> ImageSize {
        try primitiveValue.toObject()
    }

    public func encode() -> Data {
        (try? self.toData()) ?? .empty
    }
}
