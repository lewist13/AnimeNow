//
//  Loadable.swift
//  Anime Now!
//
//  Created by ErrorErrorError on 9/9/22.
//

import Foundation

enum Loadable<T> {
    case idle
    case loading
    case success(T)
    case failed
}

extension Loadable {
    var isLoading: Bool {
        switch self {
        case .loading:
            return true
        default:
            return false
        }
    }

    var hasInitialized: Bool {
        switch self {
        case .idle:
            return false
        default:
            return true
        }
    }

    var finished: Bool {
        switch self {
        case .success, .failed:
            return true
        default:
            return false
        }
    }

    var value: T? {
        if case .success(let value) = self {
            return value
        }
        return nil
    }
}

extension Loadable: Equatable where T: Equatable {}
