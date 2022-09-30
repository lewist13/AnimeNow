//
//  CDEpisodeProgress.swift
//  Anime Now! (iOS)
//
//  Created by Erik Bautista on 9/29/22.
//

import Foundation
import CoreData

final class CDEpisodeProgress: NSManagedObject {}

extension CDEpisodeProgress {
    @NSManaged public var id: ProgressInfoId?
    @NSManaged public var animeId: NSNumber?
    @NSManaged public var animeTitle: String?
    @NSManaged public var episodeId: String?
    @NSManaged public var episodeTitle: String?
    @NSManaged public var episodeThumbnailUrl: URL?
    @NSManaged public var episodeNumber: NSNumber?
    @NSManaged public var lastUpdated: Date?
    @NSManaged public var progress: NSNumber?
}

extension CDEpisodeProgress: Identifiable {}

extension CDEpisodeProgress: ManagedModel {
    static func fetchRequest() -> NSFetchRequest<CDEpisodeProgress> {
        NSFetchRequest<CDEpisodeProgress>(entityName: "CDEpisodeProgress")
    }

    var asDomain: EpisodeProgress {
        .init(
            id: id ?? .init(),
            animeTitle: animeTitle ?? "",
            episodeTitle: episodeTitle ?? "",
            episodeThumbnailUrl: episodeThumbnailUrl ?? .init(string: "/")!,
            episodeNumber: episodeNumber?.int64Value ?? 0,
            lastUpdated: lastUpdated ?? .init(),
            progress: progress?.doubleValue ?? 0.0,
            objectURL: objectID.uriRepresentation()
        )
    }

    func create(from domain: EpisodeProgress) {
        update(from: domain)
    }

    func update(from domain: EpisodeProgress) {
        id = domain.id
        animeTitle = domain.animeTitle
        episodeTitle = domain.episodeTitle
        episodeThumbnailUrl = domain.episodeThumbnailUrl
        episodeNumber = (domain.episodeNumber) as NSNumber
        lastUpdated = domain.lastUpdated
        progress = (domain.progress) as NSNumber
    }
}
