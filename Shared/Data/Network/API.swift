//
//  API.swift
//  Anime Now!
//
//  Created by ErrorErrorError on 9/4/22.
//

import Foundation
import URLRouting
import Combine

protocol APIRoutable {
    associatedtype Endpoint
    var baseURL: URL { get }
    var router: AnyParserPrinter<URLRequestData, Endpoint> { get }
    func configureRequest(request: inout URLRequest)
}

enum API {
    static func request<API: APIRoutable, Output>(
        _ api: API,
        _ endpoint: API.Endpoint,
        _ responseType: Output.Type = Output.self,
        _ decoder: JSONDecoder = .init()
    ) async throws -> Output where Output: Decodable {
        guard var request = try? api.router.baseURL(api.baseURL.absoluteString).request(for: endpoint) else {
            throw URLError(.badURL)
        }

        api.configureRequest(request: &request)

        let (data, _) = try await URLSession.shared.data(for: request)

        return try decoder.decode(Output.self, from: data)
    }

    static func request<API: APIRoutable>(
        _ api: API,
        _ endpoint: API.Endpoint
    ) async throws -> Void {
        guard var request = try? api.router.baseURL(api.baseURL.absoluteString).request(for: endpoint) else {
            throw URLError(.badURL)
        }

        api.configureRequest(request: &request)

        let (_, response) = try await URLSession.shared.data(for: request)

        guard let response = response as? HTTPURLResponse, (200..<300).contains(response.statusCode) else {
            throw URLError(.badServerResponse)
        }

        return ()
    }
}

extension URLSession {
    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        if #available(iOS 15, macOS 12.0, *) {
           return try await self.data(for: request, delegate: nil)
        } else {
            return try await withCheckedThrowingContinuation { continuation in
                let task = self.dataTask(with: request) { data, response, error in
                    guard let data = data, let response = response else {
                        let error = error ?? URLError(.badServerResponse)
                        return continuation.resume(throwing: error)
                    }

                    continuation.resume(returning: (data, response))
                }

                task.resume()
            }
        }
    }

}
