//
//  Array+Identifiable.swift
//  Anime Now!
//
//  Created by ErrorErrorError on 10/1/22.
//

import Foundation
import OrderedCollections

// MARK: Identifiable

extension Collection where Element: Identifiable, Self: RangeReplaceableCollection {
    mutating func update(_ element: Element) {
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
}

extension Set: IdentifiableArray where Element: Identifiable {
    public subscript(id id: Element.ID) -> Element? {
        get {
            first(where: { $0.id == id })
        }
        set {
            if let index = firstIndex(where: { $0.id == id }) {
                remove(at: index)
                if let newValue {
                    insert(newValue)
                }
            } else {
                if let value = newValue {
                    insert(value)
                }
            }
        }
    }
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

extension OrderedSet: IdentifiableArray where Element: Identifiable {
    public subscript(id id: Element.ID) -> Element? {
        get {
            first(where: { $0.id == id })
        }
        set {
            if let index = firstIndex(where: { $0.id == id }) {
                remove(at: index)
                if let value = newValue {
                    insert(value, at: index)
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
