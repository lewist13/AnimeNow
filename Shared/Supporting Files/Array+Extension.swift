//
//  Array+Identifiable.swift
//  Anime Now!
//
//  Created by ErrorErrorError on 10/1/22.
//

import Foundation

// MARK: Duplicates

extension Array where Element: Hashable {
    func removingDuplicates() -> [Element] {
        var addedDict = [Element: Bool]()

        return filter {
            addedDict.updateValue(true, forKey: $0) == nil
        }
    }

    mutating func removeDuplicates() {
        self = self.removingDuplicates()
    }
}

// MARK: Identifiable

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

public protocol IdentifiableArray: Collection where Element: Identifiable {
    subscript(id id: Element.ID) -> Element? { get set }
    func index(id: Element.ID) -> Int?
}

extension Array: IdentifiableArray where Element: Identifiable {
    public subscript(id id: Element.ID) -> Element? {
        get {
            first(where: { $0.id == id })
        }
        set {
            if let index = firstIndex(where: { $0.id == id }) {
                if let value = newValue {
                    self[index] = value
                } else {
                    remove(at: index)
                }
            } else {
                if let value = newValue {
                    append(value)
                }
            }
        }
    }

    public func index(id: Element.ID) -> Int? {
        firstIndex(where: { $0.id == id })
    }
}
