//
//  Collection+Safe.swift
//  
//
//  Created by ErrorErrorError on 1/9/23.
//  
//

import Foundation

public extension Collection where Self: RangeReplaceableCollection {
    subscript(safe index: Index) -> Element? {
        get {
            guard indices.contains(index) else { return nil }
            return self[index]
        } set {
            if indices.contains(index), let newValue {
                self.remove(at: index)
                self.insert(newValue, at: index)
            } else {
                self.remove(at: index)
            }
        }
    }
}
