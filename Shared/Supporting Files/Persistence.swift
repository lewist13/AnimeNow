//
//  Persistence.swift
//  Anime Now! (iOS)
//
//  Created by Erik Bautista on 9/3/22.
//

import Foundation
import CoreData

public class Persistence {
    static let shared = Persistence()

    let persistentContainer: NSPersistentContainer

    private init() {
        let bundle = Bundle(for: Persistence.self)

        guard let databaseURL = bundle.url(forResource: "AnimeNow", withExtension: "momd") else {
            fatalError("Failed to find data model")
        }

        let database = databaseURL.deletingPathExtension().lastPathComponent

        guard let managedObjectModel = NSManagedObjectModel(contentsOf: databaseURL) else {
            fatalError("Failed to create model from file: \(databaseURL)")
        }

        ProgressInfoIdTransformer.register()

        persistentContainer = .init(name: database, managedObjectModel: managedObjectModel)
        persistentContainer.loadPersistentStores { description, error in
            if let error = error {
                fatalError("Unable to load persistent stores: \(error)")
            }
        }
    }
}
