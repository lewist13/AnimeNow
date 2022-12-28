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
        _ request: Request<A, O>,
        _ decoder: JSONDecoder = .init()
    ) async throws -> O {
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

        Logger.log(
            .debug,
            "\(String(describing: A.self)) - request: \(urlRequest)"
        )

        let (data, _) = try await URLSession.shared.data(for: urlRequest)
        return try decoder.decode(O.self, from: data)
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
