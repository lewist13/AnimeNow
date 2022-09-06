//
//  API.swift
//  Anime Now!
//
//  Created by Erik Bautista on 9/4/22.
//

import Foundation
import URLRouting
import ComposableArchitecture
import SociableWeaver

protocol APIEndpoint: Equatable {
    static var router: AnyParserPrinter<URLRequestData, Self> { get }
    static var baseURL: URL { get }
    static func applyHeaders(request: inout URLRequest)
}

protocol APIRouter: Equatable {
    associatedtype T: APIEndpoint
    static var router: AnyParserPrinter<URLRequestData, T> { get }
    static var baseURL: URL { get }
    static func applyHeaders(request: inout URLRequest)
}

enum API {
    static func request<E: APIEndpoint, O: Decodable>(
        _ endpoint: E,
        _ outputType: O.Type? = nil
    ) -> Effect<O?, Error> {
        guard var request = try? E.router.baseURL(E.baseURL.absoluteString).request(for: endpoint) else {
            return .init(error: URLError(.badURL))
        }

        E.applyHeaders(request: &request)

        return URLSession.shared.dataTaskPublisher(for: request)
            .tryMap { (data, response) in
                guard let httpResponse = response as? HTTPURLResponse,
                      httpResponse.statusCode == 200 else {
                    throw URLError(.badServerResponse)
                }

                guard let outputType = outputType else {
                    return nil
                }

                do {
                    let output = try JSONDecoder().decode(outputType.self, from: data)
                    return output
                } catch {
                    print("Failed to parse response: \(String(data: data, encoding: .utf8) ?? "")")
                    throw error
                }
            }
            .eraseToEffect()
    }
}
