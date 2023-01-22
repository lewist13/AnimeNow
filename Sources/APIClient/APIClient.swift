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
    func request<A: APIBase, O: Decodable>(
        _ api: A,
        _ request: Request<A, O>
    ) async throws -> O
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

extension APIBase {
    public static var animeNowAPI: AnimeNowAPI { AnimeNowAPI.shared }
    public static var aniListAPI: AniListAPI { AniListAPI.shared }
    public static var aniSkipAPI: AniSkipAPI { AniSkipAPI.shared }
    public static var consumetAPI: ConsumetAPI { ConsumetAPI.shared }
    public static var kitsuAPI: KitsuAPI { KitsuAPI.shared }
    public static var enimeAPI: EnimeAPI { EnimeAPI.shared }
}

public struct EmptyResponse: Decodable {}

public typealias NoResponseRequest<Route: APIBase> = Request<Route, EmptyResponse>

typealias Query = URLQueryItem

extension URLQueryItem {
    init<C: CustomStringConvertible>(
        name: String,
        _ value: C
    ) {
        self.init(
            name: name,
            value: value.description
        )
    }
}

public struct Request<Route: APIBase, O: Decodable> {
    var path: [CustomStringConvertible] = []
    var query: [URLQueryItem]? = nil
    var method: Method = .get
    var headers: ((Route) -> [String: CustomStringConvertible])? = nil
    var decoder: JSONDecoder = .init()

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
