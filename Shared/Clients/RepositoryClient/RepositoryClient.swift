//
//  RepositoryClient.swift
//  Anime Now!
//
//  Created by ErrorErrorError on 9/3/22.
//

import Foundation
import ComposableArchitecture

protocol RepositoryClient {
    func insert<T: DomainModel>(_ item: T) -> Effect<T, Error>
    func update<T: DomainModel>(_ item: T) -> Effect<T, Error>
    func insertOrUpdate<T: DomainModel>(_ item: T) -> Effect<T, Error>
    func delete<T: DomainModel>(_ item: T) -> Effect<Void, Error>
    func fetch<T: DomainModel>(_ predicate: NSPredicate?,_ sort: [NSSortDescriptor]) -> Effect<[T], Error>
    func observe<T: DomainModel>(_ predicate: NSPredicate?, _ sort: [NSSortDescriptor]) -> Effect<[T], Never>
}
