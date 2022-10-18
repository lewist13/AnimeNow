//
//  API.swift
//  Anime Now!
//
//  Created by ErrorErrorError on 9/4/22.
//

import Foundation
import URLRouting
import Combine

protocol APIRoute {
    associatedtype Endpoint
    var baseURL: URL { get }
    var router: AnyParserPrinter<URLRequestData, Endpoint> { get }
    func configureRequest(request: inout URLRequest)
}

enum API {
    static func request<API: APIRoute, Output: Decodable>(
        _ api: API,
        _ endpoint: API.Endpoint,
        _ type: Output.Type? = nil
    ) -> AnyPublisher<Output, EquatableError> {
        guard var request = try? api.router.baseURL(api.baseURL.absoluteString).request(for: endpoint) else {
            return Fail(error: URLError(.badURL).toEquatableError())
                .eraseToAnyPublisher()
        }

        api.configureRequest(request: &request)

        return URLSession.shared.dataTaskPublisher(for: request)
            .map(\.data)
            .decode(type: Output.self, decoder: JSONDecoder())
            .mapError { $0.toEquatableError() }
            .eraseToAnyPublisher()
    }
}
