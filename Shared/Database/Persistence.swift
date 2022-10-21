//
//  Persistence.swift
//  Anime Now! (iOS)
//
//  Created by ErrorErrorError on 9/3/22.
//

import Foundation
import CoreData

public class Persistence {
    static let shared = Persistence()

    let persistentContainer: NSPersistentContainer

    private init() {
        let bundle = Bundle(for: Persistence.self)

        guard let databaseURL = bundle.url(
            forResource: "AnimeNow",
            withExtension: "momd"
        ) else {
            fatalError("Failed to find data model")
        }

        let database = databaseURL.deletingPathExtension().lastPathComponent

        guard let managedObjectModel = NSManagedObjectModel(contentsOf: databaseURL) else {
            fatalError("Failed to create model from file: \(databaseURL)")
        }

        persistentContainer = .init(name: database, managedObjectModel: managedObjectModel)
        persistentContainer.loadPersistentStores { description, error in
            description.shouldMigrateStoreAutomatically = true
            description.shouldInferMappingModelAutomatically = true
            if let error = error {
                fatalError("Unable to load persistent stores: \(error)")
            }
        }
    }
}

// MARK: Domain Model

protocol DomainModelConvertible: Equatable, Identifiable {
    associatedtype ManagedObject: ManagedObjectConvertible where ManagedObject.DomainModel == Self

    var objectURL: URL? { get set }

    func asManagedObject(in context: NSManagedObjectContext) -> ManagedObject
}

// MARK: Managed Model

protocol ManagedObjectConvertible: NSManagedObject {
    associatedtype DomainModel: DomainModelConvertible where DomainModel.ManagedObject == Self

    static func getFetchRequest() -> NSFetchRequest<DomainModel.ManagedObject>

    var asDomain: DomainModel { get }

    func create(from domain: DomainModel)

    func update(from domain: DomainModel)
}
