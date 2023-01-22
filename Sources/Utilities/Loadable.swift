//
//  Loadable.swift
//  Anime Now!
//
//  Created by ErrorErrorError on 9/9/22.
//

import Foundation

public enum Loadable<T> {
    case idle
    case loading
    case success(T)
    case failed(Error)
}

extension Loadable {
    public var isLoading: Bool {
        switch self {
        case .loading:
            return true
        default:
            return false
        }
    }

    public var hasInitialized: Bool {
        switch self {
        case .idle:
            return false
        default:
            return true
        }
    }

    public var finished: Bool {
        switch self {
        case .success, .failed:
            return true
        default:
            return false
        }
    }

    public var successful: Bool {
        switch self {
        case .success: return true
        default: return false
        }
    }

    public var failed: Bool {
        switch self {
        case .failed:
            return true
        default:
            return false
        }
    }

    public var value: T? {
        if case .success(let value) = self {
            return value
        }
        return nil
    }

    public func map<N>(_ mapped: @escaping (T) -> N) -> Loadable<N> {
        switch self {
        case .idle:
            return .idle
        case .loading:
            return .loading
        case .success(let item):
            return .success(mapped(item))
        case .failed(let error):
            return .failed(error)
        }
    }
}

extension Loadable: Equatable where T: Equatable {
    public static func == (lhs: Self, rhs: Self) -> Bool {
        switch (lhs, rhs) {
        case let (.success(lhs), .success(rhs)):
            return lhs == rhs
        case let (.failed(lhs), .failed(rhs)):
            return String(reflecting: lhs) == String(reflecting: rhs)
        case (.loading, .loading), (.idle, .idle):
            return true
        default:
            return false
        }
    }
}

extension Loadable {
    public init(capture body: @Sendable () async throws -> T) async {
      do {
        self = .success(try await body())
      } catch {
        self = .failed(error)
      }
    }
}
