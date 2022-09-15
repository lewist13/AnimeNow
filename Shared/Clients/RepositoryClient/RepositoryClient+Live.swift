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

extension RepositoryClient {
    // TODO: Add any core data repos here.
}

extension RepositoryClient {
    fileprivate var live: RepositoryClient<T> {
        let persistenceContainer = Persistence.shared.persistentContainer

        return RepositoryClient<T>(
            insert: { domain in
                .future { callback in
                    let context = persistenceContainer.newBackgroundContext()

                    context.perform {
                        let managedObject = domain.asManagedObject(in: context)
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
            },
            update: { domain in
                .future { callback in
                    if let objectIdURL = domain.objectURL {
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
    
                            managedObject.update(from: domain)
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
            },
            delete: { domain in
                .future { callback in
                    if let objectIdURL = domain.objectURL {
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
            },
            fetch: { predicate, sortDescriptors in
                .future { callback in
                    let fetchRequest: NSFetchRequest<T.ManagedObject> = T.ManagedObject.fetchRequest()
                    fetchRequest.sortDescriptors = sortDescriptors
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
            },
            count: { predicate in
                .future { callback in
                        let fetchRequest: NSFetchRequest<T.ManagedObject> = T.ManagedObject.fetchRequest()
                        fetchRequest.predicate = predicate

                        let context = persistenceContainer.newBackgroundContext()
    
                        context.perform {
                            do {
                                let count = try context.count(for: fetchRequest)
                                callback(.success(count))
                            } catch {
                                print("Error: \(error)")
                                callback(.failure(error))
                            }
                        }
                    }
            },
            observe: { sortDescriptors in
                .run { subscriber in
                    let fetchRequest: NSFetchRequest<T.ManagedObject> = T.ManagedObject.fetchRequest()
                    fetchRequest.sortDescriptors = sortDescriptors

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
        )
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
