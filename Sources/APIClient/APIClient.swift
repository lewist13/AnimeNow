//
//  API.swift
//
//
//  Created by ErrorErrorError on 9/4/22.
//

import Logger
import Combine
import Foundation
import ComposableArchitecture

public protocol APIClient {
    @discardableResult
    func request<A: APIBase, O>(
        _ api: A,
        _ request: Request<A, O>,
        _ decoder: JSONDecoder
    ) async throws -> O
}

extension APIClient {
    public func request<A: APIBase, O>(
        _ api: A,
        _ request: Request<A, O>,
        _ decoder: JSONDecoder = .init()
    ) async throws -> O {
        try await self.request(api, request, decoder)
    }
}

private enum APIClientKey: DependencyKey {
    static var liveValue: any APIClient = APIClientLive()
}

extension DependencyValues {
    public var apiClient: any APIClient {
      get { self[APIClientKey.self] }
      set { self[APIClientKey.self] = newValue }
    }
}

public protocol APIBase {
    static var shared: Self { get }
    var base: URL { get }
}

typealias Query = URLQueryItem

extension URLQueryItem {
    init(name: String, value: Bool) {
        self.init(
            name: name,
            value: value.description
        )
    }

    init(name: String, value: Int) {
        self.init(name: name, value: value.description)
    }
}

public struct Request<Route: APIBase, O: Decodable> {
    var path: [CustomStringConvertible] = []
    var query: [URLQueryItem]? = nil
    var method: Method = .get
    var headers: ((Route) -> [String: CustomStringConvertible])? = nil

    enum Method: CustomStringConvertible {
        case get
        case post(Data)

        var stringValue: String {
            switch self {
            case .get:
                return "GET"
            case .post:
                return "POST"
            }
        }

        var description: String {
            switch self {
            case .get:
                return "GET"
            case .post(let data):
                return "POST: \(String(data: data, encoding: .utf8) ?? "Unknown")"
            }
        }
    }
}
