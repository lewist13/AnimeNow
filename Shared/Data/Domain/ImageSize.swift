//
//  ImageSize.swift
//  Anime Now! (iOS)
//
//  Created by Erik Bautista on 9/21/22.
//

import Foundation

enum ImageSize: Hashable, Comparable {
    case tiny(URL)
    case small(URL)
    case medium(URL)
    case large(URL)
    case original(URL)

    var link: URL {
        switch self {
        case .tiny(let url):
            return url
        case .small(let url):
            return url
        case .medium(let url):
            return url
        case .large(let url):
            return url
        case .original(let url):
            return url
        }
    }

    static func < (lhs: ImageSize, rhs: ImageSize) -> Bool {
        if case .tiny = lhs {
            return true
        } else if case .small = lhs {
            if case .tiny = rhs {
                return false
            } else {
                return true
            }
        } else if case .medium = lhs {
            if case .tiny = rhs {
                return false
            } else if case .small = rhs {
                return false
            } else {
                return true
            }
        } else if case .large = lhs {
            if case .original = rhs {
                return true
            } else {
                return false
            }
        } else {
            return false
        }
    }

    var description: String {
        switch self {
        case .tiny:
            return "tiny"
        case .small:
            return "small"
        case .medium:
            return "medium"
        case .large:
            return "large"
        case .original:
            return "original"
        }
    }
}

extension Array where Element == ImageSize {
    var smallest: ImageSize? {
        self.sorted(by: { $0 < $1 }).first
    }

    var largest: ImageSize? {
        self.sorted(by: { $0 > $1 }).first
    }
}
