//
//  File.swift
//  
//
//  Created by ErrorErrorError on 1/9/23.
//  
//

import Foundation
import AVFoundation

protocol Loader {
    static var customPlaylistScheme: String { get }

    func loadResource(url: URL, completion: @escaping (Result<Data, Error>) -> Void)
}

final class BaseResourceLoaderDelegate: NSObject, AVAssetResourceLoaderDelegate {
    let loader: Loader
    let queue: DispatchQueue

    internal init(loader: Loader) {
        self.loader = loader
        self.queue = .init(
            label: "\(String(describing: loader))-\(UUID().uuidString)",
            qos: .utility
        )
    }

    func resourceLoader(
        _ resourceLoader: AVAssetResourceLoader,
        shouldWaitForLoadingOfRequestedResource loadingRequest: AVAssetResourceLoadingRequest
    ) -> Bool {
        loadRequestedResource(loadingRequest)
    }

    func loadRequestedResource(_ loadingRequest: AVAssetResourceLoadingRequest) -> Bool {
        guard let url = loadingRequest.request.url else { return false }

        if url.pathExtension == "ts" {
            loadingRequest.redirect = URLRequest(url: url.recoveryScheme)
            loadingRequest.response = HTTPURLResponse(
                url: url.recoveryScheme,
                statusCode: 302,
                httpVersion: nil,
                headerFields: nil
            )
            loadingRequest.finishLoading()
        } else {
            loader.loadResource(url: url) {
                switch $0 {
                case .success(let data):
                    loadingRequest.dataRequest?.respond(with: data)
                    loadingRequest.finishLoading()
                case .failure(let error):
                    print(error.localizedDescription)
                    loadingRequest.finishLoading(with: error)
                }
            }
        }
        return true
    }

    static let httpsScheme = "https"
}

extension URL {
    var recoveryScheme: URL {
        change(scheme: BaseResourceLoaderDelegate.httpsScheme)
    }

    func change(scheme: String) -> URL {
        var component = URLComponents(
            url: self,
            resolvingAgainstBaseURL: false
        )
        component?.scheme = scheme
        return component?.url ?? self
    }
}
