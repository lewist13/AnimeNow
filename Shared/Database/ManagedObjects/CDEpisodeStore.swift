//
//  CDEpisodeStore.swift
//  Anime Now!
//
//  Created by ErrorErrorError on 10/6/22.
//

import Sworm
import CoreData

extension EpisodeStore: ManagedObjectConvertible {
    static let entityName = "CDEpisodeStore"

    static var idKeyPath: KeyPath = \Self.id

    static let attributes: Set<Attribute<EpisodeStore>> = [
        .init(\.id, "id"),
        .init(\.number, "number"),
        .init(\.title, "title"),
        .init(\.thumbnail, "cover"),
        .init(\.isMovie, "isMovie"),
        .init(\.progress, "progress"),
        .init(\.lastUpdatedProgress, "lastUpdatedProgress"),
        .init(\.downloadURL, "downloadURL")
    ]

    struct Relations {
        let anime = ToOneRelation<AnimeStore>("animeStore")
    }

    static let relations = Relations()
}
