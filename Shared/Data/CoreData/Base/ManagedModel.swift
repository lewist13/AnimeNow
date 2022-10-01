//
//  ManagedModel.swift
//  Anime Now! (iOS)
//
//  Created by Erik Bautista on 9/3/22.
//

import CoreData

protocol ManagedModel: NSManagedObject {
    associatedtype DomainObject: DomainModel where DomainObject.ManagedObject == Self

    static func getFetchRequest() -> NSFetchRequest<DomainObject.ManagedObject>

    var asDomain: DomainObject { get }

    func create(from domain: DomainObject)

    func update(from domain: DomainObject)
}
