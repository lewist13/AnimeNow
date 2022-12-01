//
//  RepositoryClient.swift
//  Anime Now!
//
//  Created by ErrorErrorError on 9/3/22.
//

import SwiftORM
import ComposableArchitecture

protocol RepositoryClient {
    // Insert
    func insert<T: ManagedObjectConvertible>(_ item: T) async throws

    // Update
    @discardableResult
    func update<T: ManagedObjectConvertible, V: ConvertableValue>(_ id: T.ID, _ keyPath: WritableKeyPath<T, V>, _ value: V) async throws -> Bool
    @discardableResult
    func update<T: ManagedObjectConvertible, V: ConvertableValue>(_ id: T.ID, _ keyPath: WritableKeyPath<T, V?>, _ value: V?) async throws -> Bool

    // Delete
    func delete<T: ManagedObjectConvertible>(_ item: T) async throws

    func fetch<T: ManagedObjectConvertible>(_ request: Request<T>) async throws -> [T]
    func observe<T: ManagedObjectConvertible>(_ request: Request<T>) -> AsyncStream<[T]>
}

private enum RepositoryClientKey: DependencyKey {
    static let liveValue = RepositoryClientLive.shared as RepositoryClient
}

extension DependencyValues {
    var repositoryClient: RepositoryClient {
        get { self[RepositoryClientKey.self] }
        set { self[RepositoryClientKey.self] = newValue }
    }
}
