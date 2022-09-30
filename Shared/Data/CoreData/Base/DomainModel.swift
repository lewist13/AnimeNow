//
//  CoreModel.swift
//  Anime Now! (iOS)
//
//  Created by Erik Bautista on 9/3/22.
//

import CoreData

protocol DomainModel: Equatable, Identifiable {
    associatedtype ManagedObject: ManagedModel where ManagedObject.DomainObject == Self

    var objectURL: URL? { get set }

    func asManagedObject(in context: NSManagedObjectContext) -> ManagedObject
}
