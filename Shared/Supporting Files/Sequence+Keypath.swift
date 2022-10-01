//
//  Sequence+Keypath.swift
//  Anime Now!
//
//  Created by Erik Bautista on 9/30/22.
//

import Foundation

extension Sequence {
    func sorted<T: Comparable>(by keyPath: KeyPath<Element, T>) -> [Element] {
        return sorted { $0[keyPath: keyPath] < $1[keyPath: keyPath] }
    }
}
