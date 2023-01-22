//
//  APIClient+Live.swift
//  
//
//  Created by ErrorErrorError on 12/27/22.
//  
//

import Logger
import Foundation
import ComposableArchitecture

public class APIClientLive: APIClient {
    public func request<A: APIBase, O: Decodable>(
        _ api: A,
        _ request: Request<A, O>
    ) async throws -> O {
        do {
            guard var components = URLComponents(url: api.base, resolvingAgainstBaseURL: true) else {
                throw URLError(.badURL)
            }

            components.path += request.path.isEmpty ? "" : "/" + request.path.map(\.description).joined(separator: "/")
            components.queryItems = request.query

            guard let url = components.url else {
                throw URLError(.unsupportedURL)
            }

            var urlRequest = URLRequest(url: url)
            urlRequest.httpMethod = request.method.stringValue

            if case .post(let data) = request.method {
                urlRequest.httpBody = data
            }

            request.headers?(api).forEach { (key, value) in
                urlRequest.setValue(value.description, forHTTPHeaderField: key)
            }

            urlRequest.setHeaders()

            let (data, _) = try await URLSession.shared.data(for: urlRequest)
            return try request.decoder.decode(O.self, from: data)
        } catch {
            Logger.log(
                .error,
                "\(String(describing: A.self)) - \(request) failed with error: \(error)"
            )
            throw error
        }
    }
}

extension Request: CustomStringConvertible {
    public var description: String {
        return "/\(path.map(\.description).joined(separator: "/"))"
    }
}

extension URLRequest {
    fileprivate mutating func setHeaders() {
        let info = Bundle.main.infoDictionary
        let executable = info?[kCFBundleNameKey as String] ?? "Anime Now!"
        let bundle = info?[kCFBundleIdentifierKey as String] ?? "Unknown"
        let appVersion = info?["CFBundleShortVersionString"] ?? "Unknown"
        let appCommit = info?["Commit Version"] ?? "Unknown"
        let osVersion = {
            let version = ProcessInfo.processInfo.operatingSystemVersion
            return "\(version.majorVersion).\(version.minorVersion).\(version.patchVersion)"
        }()
        let osName = {
            #if os(iOS)
            #if targetEnvironment(macCatalyst)
            return "macOS(Catalyst)"
            #else
            return "iOS"
            #endif
            #elseif os(watchOS)
            return "watchOS"
            #elseif os(tvOS)
            return "tvOS"
            #elseif os(macOS)
            return "macOS"
            #else
            return "Unknown"
            #endif
        }()

        self.setValue(
            "\(executable)/\(appVersion) (\(bundle); commit:\(appCommit)) \(osName) \(osVersion)",
            forHTTPHeaderField: "User-Agent"
        )
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

    func data(from url: URL) async throws -> (Data, URLResponse) {
        if #available(iOS 15, macOS 12.0, *) {
           return try await self.data(from: url, delegate: nil)
        } else {
            return try await withCheckedThrowingContinuation { continuation in
                let task = self.dataTask(with: url) { data, response, error in
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
