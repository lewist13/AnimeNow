//
//  LoadingState.swift
//  Anime Now!
//
//  Created by Erik Bautista on 9/9/22.
//

import Foundation

enum LoadableState<T: Equatable>: Equatable {
    case preparing
    case loading
    case success(T)
    case failed

    var isLoading: Bool {
        self == .preparing || self == .loading
    }

    var loaded: Bool {
        switch self {
        case .success, .failed:
            return true
        default:
            return false
        }
    }

    var hasInitialized: Bool {
        self != .preparing
    }
}
