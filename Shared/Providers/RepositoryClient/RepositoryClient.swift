//
//  RepositoryClient.swift
//  Anime Now! (iOS)
//
//  Created by Erik Bautista on 9/3/22.
//

import Foundation
import ComposableArchitecture

struct RepositoryClient<T: DomainModel> {
    let insert: (T) -> Effect<T, Error>
    let update: (T) -> Effect<T, Error>
    let delete: (T) -> Effect<Void, Error>
    let fetch: (NSPredicate?, [NSSortDescriptor]) -> Effect<[T], Error>
    let count: (NSPredicate?) -> Effect<Int, Error>
    let observe: ([NSSortDescriptor]) -> Effect<[T], Never>
}
