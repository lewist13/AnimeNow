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

    static func request<Router: APIRoute, Output: Decodable>(
        _ router: Router,
        _ endpoint: Router.Endpoint,
        _ outputType: Output.Type? = nil
    ) -> Effect<Output?, API.Error> {
        guard var request = try? router.router.baseURL(router.baseURL.absoluteString).request(for: endpoint) else {
            return .init(error: .badURL)
        }

        router.applyHeaders(request: &request)

        return URLSession.shared.dataTaskPublisher(for: request)
            .tryMap { (data, response) in
                guard let httpResponse = response as? HTTPURLResponse,
                      httpResponse.statusCode == 200 else {
                    throw API.Error.badServerResponse(String(decoding: data, as: UTF8.self))
                }

                guard let outputType = outputType else {
                    return nil
                }

                do {
                    let output = try JSONDecoder().decode(outputType.self, from: data)
                    return output
                } catch {
                    throw API.Error.parsingFailed("\(error)")
                }
            }
            .mapError { $0 as? API.Error ?? .badServerResponse("Error received from server.") }
            .eraseToEffect()
    }
}
