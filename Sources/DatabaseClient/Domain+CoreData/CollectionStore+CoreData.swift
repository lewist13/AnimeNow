//  CollectionStore+CoreData.swift
//  Anime Now!
//
//  Created by ErrorErrorError on 11/16/22.
//  

import Foundation
import SharedModels

extension CollectionStore: ManagedObjectConvertible {
    public static let entityName = "CDCollectionStore"

    public static var idKeyPath: KeyPath = \Self.title

    public static let attributes: Set<Attribute<CollectionStore>> = [
        .init(\.title, "title"),
        .init(\.lastUpdated, "lastUpdated"),
        .init(\.animes, "animes")
    ]
}

extension CollectionStore.Title: ConvertableValue {
    public func encode() -> Data {
        (try? self.toData()) ?? .init()
    }

    public static func decode(value: Data) throws -> Self {
        try value.toObject()
    }
}
