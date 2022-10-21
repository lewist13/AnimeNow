//
//  CDEpisodeStore.swift
//  Anime Now!
//
//  Created by ErrorErrorError on 10/6/22.
//

import Foundation
import CoreData

extension CDEpisodeStore: ManagedObjectConvertible {
    static func getFetchRequest() -> NSFetchRequest<CDEpisodeStore> {
        self.fetchRequest()
    }

    var asDomain: EpisodeStore {
        .init(
            id: id ?? .init(),
            number: Int(number),
            title: title ?? "Untitled",
            thumbnail: cover?.toObject() ?? .none,
            isMovie: isMovie,
            progress: progress,
            lastUpdatedProgress: lastUpdatedProgress ?? .init(),
            downloadURL: downloadURL,
            objectURL: objectID.uriRepresentation()
        )
    }

    func create(from domain: EpisodeStore) {
        update(from: domain)
    }

    func update(from domain: EpisodeStore) {
        id = domain.id
        number = Int16(domain.number)
        title = domain.title
        cover = domain.thumbnail.toData()
        isMovie = domain.isMovie
        progress = domain.progress
        lastUpdatedProgress = domain.lastUpdatedProgress
        downloadURL = downloadURL
    }
}

extension EpisodeStore: DomainModelConvertible {
    func asManagedObject(in context: NSManagedObjectContext) -> CDEpisodeStore {
        let object = CDEpisodeStore(context: context)
        object.id = id
        object.number = Int16(number)
        object.title = title
        object.cover = thumbnail?.toData()
        object.isMovie = isMovie
        object.progress = progress
        object.lastUpdatedProgress = lastUpdatedProgress
        object.downloadURL = downloadURL
        return object
    }
}
