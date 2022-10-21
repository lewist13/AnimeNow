//
//  LoadingState.swift
//  Anime Now!
//
//  Created by ErrorErrorError on 9/9/22.
//

import Foundation

enum LoadableState<T: Equatable>: Equatable {
    case idle
    case loading
    case success(T)
    case failed
}

extension LoadableState {
    var isLoading: Bool {
        self == .loading
    }

    var finished: Bool {
        switch self {
        case .success, .failed:
            return true
        default:
            return false
        }
    }

    var hasInitialized: Bool {
        self != .idle
    }

    var value: T? {
        switch self {
        case .success(let value):
            return value
        default:
            return nil
        }
    }
}
