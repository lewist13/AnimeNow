//
//  RepositoryClient+Mock.swift
//  Anime Now! (iOS)
//
//  Created by Erik Bautista on 9/3/22.
//

import Foundation
import ComposableArchitecture

class RepositoryClientMock: RepositoryClient {
    static let shared = RepositoryClientMock()

    private init() {}

    func insert<T>(_ item: T) -> Effect<T, Error> where T : DomainModel {
        .none
    }

    func update<T>(_ item: T) -> Effect<T, Error> where T : DomainModel {
        .none
    }

    func insertOrUpdate<T>(_ item: T) -> Effect<T, Error> where T : DomainModel {
        .none
    }

    func delete<T>(_ item: T) -> Effect<Void, Error> where T : DomainModel {
        .none
    }

    func fetch<T>(_ predicate: NSPredicate?, _ sort: [NSSortDescriptor]) -> Effect<[T], Error> where T : DomainModel {
        .none
    }

    func observe<T>(_ predicate: NSPredicate?, _ sort: [NSSortDescriptor]) -> Effect<[T], Never> where T : DomainModel {
        .none
    }
}
