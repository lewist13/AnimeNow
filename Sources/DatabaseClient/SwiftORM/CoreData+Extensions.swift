//  CoreData+PersistenceContainer.swift
//  Anime Now!
//
//  Created by ErrorErrorError on 11/16/22.
//  
//  Modified version of https://github.com/prisma-ai/Sworm

import CoreData
import Foundation

public extension NSPersistentContainer {
    func schedule<T>(
        _ action: @Sendable @escaping (NSManagedObjectContext) throws -> T
    ) async throws -> T {
        try Task.checkCancellation()

        let context = self.newBackgroundContext()

        if #available(iOS 15.0, macOS 12.0, *) {
            return try await context.perform(schedule: .immediate) {
                try context.execute(action)
            }
        } else {
            return try await withUnsafeThrowingContinuation { continuation in
                continuation.resume(
                    with: .init(catching: { try context.execute(action) })
                )
            }
        }
    }
}

public extension NSManagedObjectContext {
    @discardableResult
    func insert(entity name: String) -> NSManagedObject? {
        self.persistentStoreCoordinator
            .flatMap { $0.managedObjectModel.entitiesByName[name] }
            .flatMap { .init(entity: $0, insertInto: self) }
    }

    @discardableResult
    func fetch<T: ManagedObjectConvertible>(
        _ request: Request<T>
    ) throws -> [NSManagedObject] {
        let fetchRequest: NSFetchRequest<NSManagedObject> = request.makeFetchRequest()
        return try self.fetch(fetchRequest)
    }

    @_optimize(none)
    @discardableResult
    func fetchOne<T: ManagedObjectConvertible> (
        _ request: Request<T>
    ) throws -> NSManagedObject? {
        try self.fetch(request.limit(1)).first
    }

    func delete<T: ManagedObjectConvertible>(
        _ request: Request<T>
    ) throws {
        let items = try self.fetch(request)

        for item in items {
            self.delete(item)
        }
    }
}

extension NSManagedObjectContext {
    func execute<T>(
    _ action: @Sendable @escaping (NSManagedObjectContext) throws -> T
    ) throws -> T {
        defer {
            self.reset()
        }

        let value = try action(self)

        if hasChanges {
            try self.save()
        }

        return value
    }
}

public extension NSManagedObject {
    func decode<T: ManagedObjectConvertible>() throws -> T {
        try T.init(from: self)
    }

    func update<T: ManagedObjectConvertible>(
        _ item: T
    ) throws {
        try item.encodeAttributes(to: self)
    }

    func update<T: ManagedObjectConvertible, V: ConvertableValue>(
        _ keyPath: WritableKeyPath<T, V>,
        _ value: V
    ) throws {
        self[primitiveValue: T.attribute(keyPath).name] = value.encode()
    }

    func update<T: ManagedObjectConvertible, V: ConvertableValue>(
        _ keyPath: WritableKeyPath<T, V?>,
        _ value: V?
    ) throws {
        self[primitiveValue: T.attribute(keyPath).name] = value?.encode()
    }
}

extension NSManagedObject {
    subscript(primitiveValue forKey: String) -> Any? {
        get {
            defer { didAccessValue(forKey: forKey) }
            willAccessValue(forKey: forKey)
            return primitiveValue(forKey: forKey)
        }
        set (newValue) {
            defer { didChangeValue(forKey: forKey) }
            willChangeValue(forKey: forKey)
            setPrimitiveValue(newValue, forKey: forKey)
        }
    }
}
