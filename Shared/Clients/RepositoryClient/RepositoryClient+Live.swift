//
//  RepositoryClient+Live.swift
//  Anime Now! (iOS)
//
//  Created by Erik Bautista on 9/3/22.
//

import Foundation
import ComposableArchitecture
import CoreData
import Combine

class RepositoryClientLive: RepositoryClient {
    let persistenceContainer = Persistence.shared.persistentContainer

    func insert<T>(_ item: T) -> Effect<T, Error> where T : DomainModel {
        .future { [unowned self] callback in
            let context = persistenceContainer.newBackgroundContext()

            context.perform {
                let managedObject = item.asManagedObject(in: context)
                do {
                    context.insert(managedObject)
                    try context.save()
                    callback(.success(managedObject.asDomain))
                } catch {
                    let nserror = error as NSError
                    callback(.failure(error))
                    print("Unresolved error \(nserror)")
                }
            }
        }
    }

    func update<T>(_ item: T) -> Effect<T, Error> where T : DomainModel {
        .future { [unowned self] callback in
            if let objectIdURL = item.objectURL {
                let context = persistenceContainer.newBackgroundContext()

                context.perform {
                    guard let managedObjectId = context.persistentStoreCoordinator?.managedObjectID(
                        forURIRepresentation:objectIdURL
                    ) else {
                        return
                    }
                    let _managedObject = context.object(with: managedObjectId)

                    guard let managedObject = _managedObject as? T.ManagedObject else {
                        return
                    }

                    managedObject.update(from: item)
                    do {
                        try context.save()
                        callback(.success(managedObject.asDomain))
                    } catch {
                        let nserror = error as NSError
                        print("Unresolved error \(nserror)")
                        callback(.failure(error))
                    }
                }
            }
        }
    }
    
    func delete<T>(_ item: T) -> Effect<Void, Error> where T : DomainModel {
        .future { [unowned self] callback in
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
                        callback(.success(()))
                    } catch {
                        let nserror = error as NSError
                        print("Unresolved error \(nserror)")
                        callback(.failure(error))
                    }
                }
            }
        }
    }
    
    func fetch<T>(_ predicate: NSPredicate?, _ sort: [NSSortDescriptor]) -> Effect<[T], Error> where T : DomainModel {
        .future { [unowned self] callback in
            let fetchRequest: NSFetchRequest<T.ManagedObject> = T.ManagedObject.fetchRequest()
            fetchRequest.sortDescriptors = sort
            fetchRequest.predicate = predicate

            let context = persistenceContainer.newBackgroundContext()

            context.perform {
                do {
                    let data = try context.fetch(fetchRequest).map(\.asDomain)
                    callback(.success(data))
                } catch {
                    print("Error: \(error)")
                    callback(.failure(error))
                }
            }
        }
    }
    
//    func count<T>(_ predicate: NSPredicate?, _ stub: T) -> Effect<Int, Error> {
//        .future { callback in
//                let fetchRequest: NSFetchRequest<T.ManagedObject> = T.ManagedObject.fetchRequest()
//                fetchRequest.predicate = predicate
//
//                let context = persistenceContainer.newBackgroundContext()
//
//                context.perform {
//                    do {
//                        let count = try context.count(for: fetchRequest)
//                        callback(.success(count))
//                    } catch {
//                        print("Error: \(error)")
//                        callback(.failure(error))
//                    }
//                }
//            }
//    }
    
    func observe<T>(_ sort: [NSSortDescriptor]) -> Effect<[T], Never> where T : DomainModel {
        .run { [unowned self] subscriber in
            let fetchRequest: NSFetchRequest<T.ManagedObject> = T.ManagedObject.fetchRequest()
            fetchRequest.sortDescriptors = sort

            let context = persistenceContainer.newBackgroundContext()
            context.automaticallyMergesChangesFromParent = true

            let fetchedResultsController = NSFetchedResultsController(
                fetchRequest: fetchRequest,
                managedObjectContext: context,
                sectionNameKeyPath: nil,
                cacheName: nil
            )

            let delegate = FetchedResultsControllerDelegate<T>(subscriber)
            fetchedResultsController.delegate = delegate

            fetchedResultsController.managedObjectContext.perform {
                do {
                    try fetchedResultsController.performFetch()
                    let newData = fetchedResultsController.fetchedObjects.map({ $0.map(\.asDomain) })
                    subscriber.send(newData ?? [])
                } catch {
                    subscriber.send([])
                }
            }

            return AnyCancellable {
                subscriber.send(completion: .finished)
                fetchedResultsController.delegate = nil
                _ = delegate
            }
        }
    }
}

private class FetchedResultsControllerDelegate<T: DomainModel>: NSObject, NSFetchedResultsControllerDelegate {
    let subscriber: Effect<[T], Never>.Subscriber

    init(_ subscriber: Effect<[T], Never>.Subscriber) {
        self.subscriber = subscriber
        super.init()
    }

    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        controller.managedObjectContext.perform { [unowned self] in
            if controller.fetchedObjects?.isEmpty ?? true {
                do {
                    try controller.performFetch()
                } catch {
                    print("There was an error fetching.")
                }
            }
            
            let items = controller.fetchedObjects as? [T.ManagedObject] ?? []
            
            self.subscriber.send(items.map(\.asDomain))
        }
    }
}
