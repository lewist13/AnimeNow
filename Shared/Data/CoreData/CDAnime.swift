//
//  CDAnime.swift
//  Anime Now!
//
//  Created by Erik Bautista on 9/30/22.
//

import Foundation
import CoreData

extension CDAnime: ManagedModel {
    static func getFetchRequest() -> NSFetchRequest<CDAnime> {
        Self.fetchRequest()
    }

    var asDomain: AnimeDBModel {
        .init(
            id: id,
            isFavorite: isFavorite,
            progressInfos: progressInfos?.toObject() ?? .init(),
            objectURL: objectID.uriRepresentation()
        )
    }

    func create(from domain: AnimeDBModel) {
        update(from: domain)
    }

    func update(from domain: AnimeDBModel) {
        id = domain.id
        isFavorite = domain.isFavorite
        progressInfos = domain.progressInfos.toData()
    }
}

extension AnimeDBModel: DomainModel {
    func asManagedObject(in context: NSManagedObjectContext) -> CDAnime {
        let object = CDAnime(context: context)
        object.id = id
        object.isFavorite = isFavorite
        object.progressInfos = progressInfos.toData()
        return object
    }
}
