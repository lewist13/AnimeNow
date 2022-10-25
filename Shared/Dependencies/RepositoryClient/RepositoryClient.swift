//
//  RepositoryClient.swift
//  Anime Now!
//
//  Created by ErrorErrorError on 9/3/22.
//

import Foundation
import ComposableArchitecture

protocol RepositoryClient {
    func insert<T: DomainModelConvertible>(_ item: T) async throws -> T
    func update<T: DomainModelConvertible>(_ item: T) async throws -> T
    func insertOrUpdate<T: DomainModelConvertible>(_ item: T) async throws -> T
    func delete<T: DomainModelConvertible>(_ item: T) async throws -> Void
    func fetch<T: DomainModelConvertible>(_ predicate: NSPredicate?, _ sort: [NSSortDescriptor]) async throws -> [T]
    func observe<T: DomainModelConvertible>(_ predicate: NSPredicate?, _ sort: [NSSortDescriptor], _ allChanges: Bool) -> AsyncStream<[T]>
}

extension RepositoryClient {
    func observe<T: DomainModelConvertible>(
        _ predicate: NSPredicate? = nil,
        _ sort: [NSSortDescriptor] = [],
        _ notifyChildChanges: Bool = false
    ) -> AsyncStream<[T]> {
        return observe(predicate, sort, notifyChildChanges)
    }

    func fetch<T: DomainModelConvertible>(
        _ predicate: NSPredicate? = nil,
        _ sort: [NSSortDescriptor] = []
    ) async throws -> [T] {
        try await fetch(predicate, sort)
    }
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
