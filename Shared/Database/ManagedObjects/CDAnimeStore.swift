//
//  CDAnimeStore.swift
//  Anime Now!
//
//  Created by ErrorErrorError on 9/30/22.
//

import Foundation
import CoreData

extension CDAnimeStore: ManagedObjectConvertible {
    static func getFetchRequest() -> NSFetchRequest<CDAnimeStore> {
        Self.fetchRequest()
    }

    var asDomain: AnimeStore {
        .init(
            id: Anime.ID(id),
            title: title ?? "",
            format: format?.toObject() ?? .tv,
            posterImage: posterImage?.toObject() ?? [],
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
        title = domain.title
        format = domain.format.toData()
        posterImage = domain.posterImage.toData()
        isFavorite = domain.isFavorite

        // TODO: Improve updating items in episode stores
        if let managedObjectContext = managedObjectContext {
            episodeStores = .init(
                array: domain.episodeStores.map { $0.asManagedObject(in: managedObjectContext) }
            )
        }
    }
}

extension AnimeStore: DomainModelConvertible {
    func asManagedObject(in context: NSManagedObjectContext) -> CDAnimeStore {
        let object = CDAnimeStore(context: context)
        object.id = Int64(id)
        object.title = title
        object.format = format.toData()
        object.posterImage = posterImage.toData()

        object.isFavorite = isFavorite
        object.episodeStores = .init(array: episodeStores.map { $0.asManagedObject(in: context) })
        return object
    }
}
