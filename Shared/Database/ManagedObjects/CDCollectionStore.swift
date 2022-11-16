////  CDCollectionStore.swift
//  Anime Now!
//
//  Created by ErrorErrorError on 10/28/22.
//
//

import Sworm
import CoreData

extension CollectionStore: ManagedObjectConvertible {
    static let entityName = "CDCollectionStore"

    static var idKeyPath: KeyPath = \Self.title

    static let attributes: Set<Attribute<CollectionStore>> = [
        .init(\.title, "title"),
        .init(\.lastUpdated, "lastUpdated")
    ]

    struct Relations {
        let animes = ToManyOrderedRelation<AnimeStore>(\CollectionStore.animes, "animes")
    }

    static let relations = Relations()
}

extension CollectionStore.Title: SupportedAttributeType {
    public func encodePrimitiveValue() -> Data {
        self.toData() ?? .empty
    }

    static func decode(primitiveValue: Data) throws -> Self {
        guard let format: Self = primitiveValue.toObject() else {
            throw AttributeError.badInput(primitiveValue)
        }
        return format
    }
}
