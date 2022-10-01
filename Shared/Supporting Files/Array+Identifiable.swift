//
//  Array+Identifiable.swift
//  Anime Now!
//
//  Created by Erik Bautista on 10/1/22.
//

import Foundation

extension Array where Element: Identifiable {
    mutating func insertOrUpdate(_ element: Element) {
        if let index = self.firstIndex(where: { $0.id == element.id }) {
            self.remove(at: index)
            self.insert(element, at: index)
        } else {
            self.append(element)
        }
    }
}
