//
//  RepositoryClient.swift
//  Anime Now!
//
//  Created by ErrorErrorError on 9/3/22.
//

import Foundation
import ComposableArchitecture

protocol RepositoryClient {
    func insert<T: DomainModelConvertible>(_ item: T) -> Effect<T, Error>
    func update<T: DomainModelConvertible>(_ item: T) -> Effect<T, Error>
    func insertOrUpdate<T: DomainModelConvertible>(_ item: T) -> Effect<T, Error>
    func delete<T: DomainModelConvertible>(_ item: T) -> Effect<Void, Error>
    func fetch<T: DomainModelConvertible>(_ predicate: NSPredicate?, _ sort: [NSSortDescriptor]) -> Effect<[T], Error>
    func observe<T: DomainModelConvertible>(_ predicate: NSPredicate?, _ sort: [NSSortDescriptor], _ allChanges: Bool) -> Effect<[T], Never>
}

extension RepositoryClient {
    func observe<T: DomainModelConvertible>(
        _ predicate: NSPredicate? = nil,
        _ sort: [NSSortDescriptor] = [],
        _ notifyChildChanges: Bool = false
    ) -> Effect<[T], Never> {
        observe(predicate, sort, notifyChildChanges)
    }

    func fetch<T: DomainModelConvertible>(
        _ predicate: NSPredicate? = nil,
        _ sort: [NSSortDescriptor] = []
    ) -> Effect<[T], Error> {
        fetch(predicate, sort)
    }
}
