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
            animes: (animes as? Set<CDAnimeStore>)?.map(\.asDomain) ?? [],
            name: name ?? "",
            lastUpdated: lastUpdated ?? .init(),
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
        name = domain.name
        lastUpdated = domain.lastUpdated

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
        object.name = name
        object.lastUpdated = lastUpdated
        object.animes = .init(array: animes.map { $0.asManagedObject(in: context) })
        return object
    }
}
