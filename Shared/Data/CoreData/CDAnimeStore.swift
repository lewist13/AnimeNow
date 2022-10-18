//
//  CDAnimeStore.swift
//  Anime Now!
//
//  Created by ErrorErrorError on 9/30/22.
//

import Foundation
import CoreData

extension CDAnimeStore: ManagedModel {
    static func getFetchRequest() -> NSFetchRequest<CDAnimeStore> {
        Self.fetchRequest()
    }

    var asDomain: AnimeStore {
        .init(
            id: Anime.ID(id),
            isFavorite: isFavorite,
            episodeStores: (episodeStores as? Set<CDEpisodeStore>)?.map(\.asDomain) ?? [],
            objectURL: objectID.uriRepresentation()
        )
    }

    func create(from domain: AnimeStore) {
        update(from: domain)
    }

    func update(from domain: AnimeStore) {
        id = Int64(domain.id)
        isFavorite = domain.isFavorite
        if let managedObjectContext = managedObjectContext {
            episodeStores = .init(
                array: domain.episodeStores.map { $0.asManagedObject(in: managedObjectContext) }
            )
        }
    }
}

extension AnimeStore: DomainModel {
    func asManagedObject(in context: NSManagedObjectContext) -> CDAnimeStore {
        let object = CDAnimeStore(context: context)
        object.id = Int64(id)
        object.isFavorite = isFavorite
        object.episodeStores = .init(array: episodeStores.map { $0.asManagedObject(in: context) })
        return object
    }
}
