//
//  RepositoryClient+Live.swift
//  Anime Now! (iOS)
//
//  Created by ErrorErrorError on 9/3/22.
//

import Foundation
import ComposableArchitecture
import CoreData
import Combine

class RepositoryClientLive: RepositoryClient {
    static let shared = RepositoryClientLive()

    let persistenceContainer = Persistence.shared.persistentContainer

    private init() {}

    func insert<T: DomainModelConvertible>(_ item: T) async throws -> T {
        return try await withCheckedThrowingContinuation { continuation in
            let context = persistenceContainer.newBackgroundContext()

            context.perform {
                let managedObject = item.asManagedObject(in: context)

                do {
                    context.insert(managedObject)
                    try context.save()
                    continuation.resume(with: .success(managedObject.asDomain))
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    func update<T: DomainModelConvertible>(_ item: T) async throws -> T {
        return try await withCheckedThrowingContinuation { continuation in
            if let objectIdURL = item.objectURL {
                let context = persistenceContainer.newBackgroundContext()

                context.perform {
                    guard let managedObjectId = context.persistentStoreCoordinator?.managedObjectID(
                        forURIRepresentation: objectIdURL
                    ) else {
                        return
                    }
                    let managedObject = context.object(with: managedObjectId)

                    guard let managedObject = managedObject as? T.ManagedObject else {
                        return
                    }

                    managedObject.update(from: item)
                    do {
                        try context.save()
                        continuation.resume(with: .success(managedObject.asDomain))
                    } catch {
                        continuation.resume(throwing: error)
                    }
                }
            } else {
                continuation.resume(throwing: NSError(domain: "Failed to update item. Item has no objectURL.", code: 0))
            }
        }
    }

    func insertOrUpdate<T: DomainModelConvertible>(_ item: T) async throws -> T {
        if item.objectURL != nil {
            return try await update(item)
        } else {
            return try await insert(item)
        }
    }

    func delete<T: DomainModelConvertible>(_ item: T) async throws -> Void {
        return try await withCheckedThrowingContinuation { continuation in
            if let objectIdURL = item.objectURL {
                let context = persistenceContainer.newBackgroundContext()

                context.perform {
                    guard let managedObjectId = context.persistentStoreCoordinator?.managedObjectID(
                        forURIRepresentation: objectIdURL)
                    else {
                        return
                    }
                    let managedObject = context.object(with: managedObjectId)
                    context.delete(managedObject)
                    do {
                        try context.save()
                        continuation.resume(returning: ())
                    } catch {
                        continuation.resume(throwing: error)
                    }
                }
            }
        }
    }

    func fetch<T: DomainModelConvertible>(_ predicate: NSPredicate?, _ sort: [NSSortDescriptor]) async throws -> [T] {
        return try await withCheckedThrowingContinuation { continuation in
            let fetchRequest: NSFetchRequest<T.ManagedObject> = T.ManagedObject.getFetchRequest()
            fetchRequest.sortDescriptors = sort
            fetchRequest.predicate = predicate

            let context = persistenceContainer.newBackgroundContext()

            context.perform {
                do {
                    let data = try context.fetch(fetchRequest).map(\.asDomain)
                    continuation.resume(returning: data)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    func observe<T: DomainModelConvertible>(
        _ predicate: NSPredicate?,
        _ sort: [NSSortDescriptor],
        _ notifyChildChanges: Bool
    ) -> AsyncStream<[T]> {
        .init { continuation in
            let fetchRequest: NSFetchRequest<T.ManagedObject> = T.ManagedObject.getFetchRequest()
            fetchRequest.predicate = predicate
            fetchRequest.sortDescriptors = sort

            let context = persistenceContainer.newBackgroundContext()
            context.automaticallyMergesChangesFromParent = true

            let frc = NSFetchedResultsController(
                fetchRequest: fetchRequest,
                managedObjectContext: context,
                sectionNameKeyPath: nil,
                cacheName: nil
            )

            let delegate = FetchedResultsControllerDelegate<T>(continuation)

            frc.delegate = delegate

            if let fetchRequest = frc as? NSFetchedResultsController<NSFetchRequestResult> {
                delegate.controllerDidChangeContent(fetchRequest)
            }

            let observingChildNotifications: AnyCancellable?

            if notifyChildChanges {
                observingChildNotifications = NotificationCenter.default.publisher(
                    for: NSManagedObjectContext.didChangeObjectsNotification
                )
                .compactMap({ $0.object as? NSManagedObjectContext })
                .compactMap { (try? $0.fetch(fetchRequest).map(\.asDomain)) }
                .sink {
                    continuation.yield($0)
                }
            } else {
                observingChildNotifications = nil
            }

            continuation.onTermination = { _ in
                observingChildNotifications?.cancel()
                frc.delegate = nil
                _ = delegate
            }
        }
    }
}

private class FetchedResultsControllerDelegate<T: DomainModelConvertible>: NSObject, NSFetchedResultsControllerDelegate {
    let continuation: AsyncStream<[T]>.Continuation

    init(_ continuation: AsyncStream<[T]>.Continuation) {
        self.continuation = continuation
        super.init()
    }

    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        controller.managedObjectContext.perform { [unowned self] in
            if controller.fetchedObjects == nil {
                do {
                    try controller.performFetch()
                } catch {
                    print("There was an error fetching \(String(describing: T.ManagedObject.self)).")
                    continuation.yield([])
                }
            }

            let items = controller.fetchedObjects as? [T.ManagedObject] ?? []

            self.continuation.yield(items.map(\.asDomain))
        }
    }
}
