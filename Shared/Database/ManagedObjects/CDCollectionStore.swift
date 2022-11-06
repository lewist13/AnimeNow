////  CDCollectionStore.swift
//  Anime Now!
//
//  Created by ErrorErrorError on 10/28/22.
//  
//

import Foundation
import CoreData

extension CDCollectionStore: ManagedObjectConvertible {
    static func getFetchRequest() -> NSFetchRequest<CDCollectionStore> {
        self.fetchRequest()
    }

    var asDomain: CollectionStore {
        return .init(
            id: id ?? .init(),
            title: title ?? "Unknown",
            lastUpdated: lastUpdated ?? .init(),
            userRemovable: userRemovable,
            animes: (animes as? Set<CDAnimeStore>)?.map(\.asDomain) ?? [],
            objectURL: objectID.uriRepresentation()
        )
    }

    func create(
        from domain: CollectionStore
    ) {
        update(from: domain)
    }

    func update(
        from domain: CollectionStore
    ) {
        id = domain.id
        title = domain.title
        lastUpdated = domain.lastUpdated
        userRemovable = domain.userRemovable

        // TODO: Improve updating items in episode stores
        if let managedObjectContext = managedObjectContext {
            animes = .init(
                array: domain.animes.map { $0.asManagedObject(in: managedObjectContext) }
            )
        }
    }
}

extension CollectionStore: DomainModelConvertible {
    func asManagedObject(
        in context: NSManagedObjectContext
    ) -> CDCollectionStore {
        let object = CDCollectionStore(context: context)
        object.id = id
        object.title = title
        object.lastUpdated = lastUpdated
        object.userRemovable = userRemovable
        object.animes = .init(array: animes.map { $0.asManagedObject(in: context) })
        return object
    }
}
