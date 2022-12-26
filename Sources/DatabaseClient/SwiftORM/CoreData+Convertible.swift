//  CoreData+Convertible.swift
//  Anime Now!
//
//  Created by ErrorErrorError on 11/16/22.
//  
//  Modified version of https://github.com/prisma-ai/Sworm

import Foundation

public protocol ManagedObjectConvertible {
    associatedtype ID: ConvertableValue where ID: Equatable
    static var entityName: String { get }
    static var idKeyPath: KeyPath<Self, ID> { get }
    static var attributes: Set<Attribute<Self>> { get }

    init()
}
