//  Model5ToModel6Policy.swift
//  Anime Now!
//
//  Created by ErrorErrorError on 11/17/22.
//  
//

import CoreData
import Foundation


// This model policy adds constraints to the models
// - CDCollectionStore - title as a constraint
// - CDAnimeStore - id as a constraint
// - CDEpisodeStore - id as a constraint

class Model5ToModel6Policy: NSEntityMigrationPolicy {
    override func createDestinationInstances(
        forSource sInstance: NSManagedObject,
        in mapping: NSEntityMapping,
        manager: NSMigrationManager
    ) throws {
        // TODO: Add constraints
        let managedContext = manager.sourceContext

        if sInstance.entity.name == "CDCollectionStore" {
            let fetchRequest = NSFetchRequest<NSManagedObject>.init(entityName: "CDCollectionStore")
            let results = try managedContext.fetch(fetchRequest)

            Self.deleteDuplicates(forKey: "title", managedContext, results, Data.self)
        } else if sInstance.entity.name == "CDAnimeStore" {
            let fetchRequest = NSFetchRequest<NSManagedObject>.init(entityName: "CDAnimeStore")
            let results = try managedContext.fetch(fetchRequest)

            Self.deleteDuplicates(forKey: "id", managedContext, results, Int64.self)
        } else if sInstance.entity.name == "CDEpisodeStore" {
            let fetchRequest = NSFetchRequest<NSManagedObject>.init(entityName: "CDEpisodeStore")
            let results = try managedContext.fetch(fetchRequest)

            Self.deleteDuplicates(forKey: "id", managedContext, results, Int16.self)
        }
    }

    private static func deleteDuplicates<Cast: Hashable>(
        forKey: String,
        _ managedContext: NSManagedObjectContext,
        _ results: [NSManagedObject],
        _ type: Cast.Type
    ) {
        let uniqueIds = Set(results.compactMap({ $0.value(forKeyPath: forKey) as? Cast }))
        for id in uniqueIds {
            let items = results.filter({ $0.value(forKeyPath: forKey) as? Cast == id })

            if items.count > 1 {
                for i in 1...(items.count - 1) {
                    managedContext.delete(items[i])
                }
            }
        }
    }
}
