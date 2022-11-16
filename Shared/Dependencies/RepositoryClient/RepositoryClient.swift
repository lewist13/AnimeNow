//
//  RepositoryClient.swift
//  Anime Now!
//
//  Created by ErrorErrorError on 9/3/22.
//

import Sworm
import Foundation
import ComposableArchitecture

protocol RepositoryClient {
    func insert<T: ManagedObjectConvertible>(_ item: T) async throws
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
