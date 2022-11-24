//  CollectionStore+CoreData.swift
//  Anime Now!
//
//  Created by ErrorErrorError on 11/16/22.
//  

import SwiftORM
import Foundation

extension CollectionStore: ManagedObjectConvertible {
    static let entityName = "CDCollectionStore"

    static var idKeyPath: KeyPath = \Self.title

    static let attributes: Set<Attribute<CollectionStore>> = [
        .init(\.title, "title"),
        .init(\.lastUpdated, "lastUpdated"),
        .init(\.animes, "animes")
    ]
}

extension CollectionStore.Title: ConvertableValue {
    func encode() -> Data {
        (try? self.toData()) ?? .empty
    }

    static func decode(value: Data) throws -> Self {
        try value.toObject()
    }
}
