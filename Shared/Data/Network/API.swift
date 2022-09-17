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
import Combine

protocol APIRoute {
    associatedtype Endpoint
    var baseURL: URL { get }
    var router: AnyParserPrinter<URLRequestData, Endpoint> { get }
    func applyHeaders(request: inout URLRequest)
}

enum API {
    enum Error: Swift.Error, Equatable {
        case badURL
        case badServerResponse(String)
        case authenticationFailed
        case parsingFailed(String)
    }

    static func request<API: APIRoute, Output: Decodable>(
        _ api: API,
        _ endpoint: API.Endpoint,
        _ outputType: Output.Type? = nil
    ) -> AnyPublisher<Output?, Self.Error> {
        guard var request = try? api.router.baseURL(api.baseURL.absoluteString).request(for: endpoint) else {
            return Fail(error: Self.Error.badURL)
                .eraseToAnyPublisher()
        }

        api.applyHeaders(request: &request)

        return URLSession.shared.dataTaskPublisher(for: request)
            .tryMap { (data, response) in
                guard let httpResponse = response as? HTTPURLResponse,
                      httpResponse.statusCode == 200 else {
                    throw Self.Error.badServerResponse(String(decoding: data, as: UTF8.self))
                }

                guard let outputType = outputType else {
                    return nil
                }

                do {
                    let output = try JSONDecoder().decode(outputType.self, from: data)
                    return output
                } catch {
                    throw Self.Error.parsingFailed("Failed to parse to: \(outputType.self) - \(error)")
                }
            }
            .mapError { $0 as? Self.Error ?? .badServerResponse("Error received from server.") }
            .eraseToAnyPublisher()
    }
}
