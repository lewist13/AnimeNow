////  CoreData+SortDescriptors.swift
//  Anime Now!
//
//  Created by ErrorErrorError on 11/16/22.
//  
//  Modified version of https://github.com/prisma-ai/Sworm

import Foundation

struct SortDescriptor: Equatable {
    let keyPathString: String
    var ascending: Bool = true
}

extension SortDescriptor {
    var object: NSSortDescriptor {
        .init(
            key: keyPathString,
            ascending: ascending
        )
    }
}

extension SortDescriptor {
    init<Root, Value>(
        keyPath: KeyPath<Root, Value>,
        ascending: Bool
    ) {
        self.keyPathString = NSExpression(forKeyPath: keyPath).keyPath
        self.ascending = ascending
    }
}
