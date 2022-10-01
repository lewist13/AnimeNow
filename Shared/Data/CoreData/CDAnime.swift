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

    var asDomain: AnimeStoredInfo {
        .init(
            id: id,
            isFavorite: isFavorite,
            episodesInfo: progressInfos?.toObject() ?? .init(),
            objectURL: objectID.uriRepresentation()
        )
    }

    func create(from domain: AnimeStoredInfo) {
        update(from: domain)
    }

    func update(from domain: AnimeStoredInfo) {
        id = domain.id
        isFavorite = domain.isFavorite
        progressInfos = domain.episodesInfo.toData()
    }
}

extension AnimeStoredInfo: DomainModel {
    func asManagedObject(in context: NSManagedObjectContext) -> CDAnime {
        let object = CDAnime(context: context)
        object.id = id
        object.isFavorite = isFavorite
        object.progressInfos = episodesInfo.toData()
        return object
    }
}
