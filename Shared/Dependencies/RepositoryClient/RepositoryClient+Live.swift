//  RepositoryClient+Live.swift
//  Anime Now!
//
//  Created by ErrorErrorError on 9/3/22.
//

import Sworm
import CoreData
import Foundation
import OrderedCollections

class RepositoryClientLive: RepositoryClient {
    static let shared = RepositoryClientLive()
    private let db: PersistentContainer

    private init() {
        let bundle = Bundle(for: RepositoryClientLive.self)

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

        let pc = NSPersistentContainer(name: database, managedObjectModel: managedObjectModel)
        pc.loadPersistentStores { description, error in
            if let error = error {
                fatalError("Unable to load persistent stores: \(error)")
            }

            description.shouldMigrateStoreAutomatically = false
            description.shouldInferMappingModelAutomatically = true
            pc.viewContext.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
        }
        db = .init(
            managedObjectContext: pc.newBackgroundContext,
            logError: { error in
                print(error)
            }
        )
    }

    func insert<T: ManagedObjectConvertible>(
        _ item: T
    ) async throws {
        try await self.db.schedule { ctx in
            let mainObject: ManagedObject<T>

            if let object = try ctx.fetchOne(T.all.where(T.idKeyPath == item[keyPath: T.idKeyPath])) {
                mainObject = object.encode(item)
            } else {
                mainObject = try ctx.insert(item)
            }

            try mainObject.syncRelations(ctx, with: item)
        }
    }

    func delete<T: ManagedObjectConvertible>(
        _ item: T
    ) async throws {
        try await self.db.schedule { ctx in
            try ctx.delete(T.all.where(T.idKeyPath == item[keyPath: T.idKeyPath]))
        }
    }

    func fetch<
        T: ManagedObjectConvertible
    >(
        _ request: Request<T>
    ) async throws -> [T] {
        try await db.schedule { ctx in
            try ctx.fetch(request).map { try $0.decode() }
        }
    }

    func observe<
        T: ManagedObjectConvertible
    >(
        _ request: Request<T>
    ) -> AsyncStream<[T]> {
        .init { continuation in
            Task.detached { [unowned self] in
                let values = try? await self.fetch(request)
                continuation.yield(values ?? [])

                let observe = NotificationCenter.default.observeNotifications(
                    from: NSManagedObjectContext.didSaveObjectsNotification
                )

                for await _ in observe {
                    let values = try? await self.fetch(request)
                    continuation.yield(values ?? [])
                }
            }
        }
    }
}
