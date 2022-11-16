////  Set+Identifiable.swift
//  Anime Now!
//
//  Created by ErrorErrorError on 11/15/22.
//  
//

import Foundation

extension Set where Element: Identifiable {
    mutating func update(_ element: Element) {
        if let index = self.firstIndex(where: { $0.id == element.id }) {
            self.remove(at: index)
        }
        self.insert(element)
    }
}
