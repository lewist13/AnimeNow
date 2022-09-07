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
    static func request<Router: APIRoute, Output: Decodable>(
        _ router: Router,
        _ endpoint: Router.Endpoint,
        _ outputType: Output.Type? = nil
    ) -> Effect<Output?, Error> {
        guard var request = try? router.router.baseURL(router.baseURL.absoluteString).request(for: endpoint) else {
            return .init(error: URLError(.badURL))
        }

        router.applyHeaders(request: &request)

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
