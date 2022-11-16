//
//  CDAnimeStore.swift
//  Anime Now!
//
//  Created by ErrorErrorError on 9/30/22.
//

import Sworm
import CoreData

extension AnimeStore: ManagedObjectConvertible {
    static let entityName = "CDAnimeStore"

    static var idKeyPath: KeyPath = \Self.id

    static let attributes: Set<Attribute<AnimeStore>> = [
        .init(\.id, "id"),
        .init(\.title, "title"),
        .init(\.posterImage, "posterImage"),
        .init(\.isFavorite, "isFavorite"),
        .init(\.format, "format")
    ]

    struct Relations {
        let episodes = ToManyRelation<EpisodeStore>(\AnimeStore.episodes, "episodeStores")
        let collections = ToManyRelation<CollectionStore>("collectionStore")
    }

    static let relations = Relations()
}

extension ImageSize: SupportedAttributeType {
    public func encodePrimitiveValue() -> Data {
        self.toData() ?? .empty
    }

    public static func decode(primitiveValue: Data) throws -> Self {
        guard let format: Self = primitiveValue.toObject() else {
            throw AttributeError.badInput(primitiveValue)
        }
        return format
    }
}

extension Array: SupportedAttributeType where Element == ImageSize {
    public func encodePrimitiveValue() -> Data {
        self.toData() ?? .empty
    }

    public static func decode(primitiveValue: Data) throws -> Self {
        guard let format: Self = primitiveValue.toObject() else {
            throw AttributeError.badInput(primitiveValue)
        }
        return format
    }
}

extension Anime.Format: SupportedAttributeType {
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
