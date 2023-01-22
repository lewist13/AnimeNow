//
//  VideoPlayerItem.swift
//  
//
//  Created by ErrorErrorError on 1/17/23.
//  
//

import Foundation
import AVFoundation

final class VideoPlayerItem: AVPlayerItem {
    static let dashCustomPlaylistScheme = "anime-now-mpd"
    static let hlsCustomPlaylistScheme = "anime-now-hls"

    internal let payload: VideoPlayerClient.Payload

    private let resourceQueue = DispatchQueue(label: "videoplayeritem-\(UUID().uuidString)")

    enum ResourceLoaderError: Swift.Error {
        case responseError
        case emptyData
        case failedToCreateM3U8
    }

    init(_ payload: VideoPlayerClient.Payload) {
        self.payload = payload

        let headers = payload.source.headers ?? [:]
        let url: URL

        if payload.source.format == .mpd {
            url = payload.source.url.change(scheme: Self.dashCustomPlaylistScheme)
//        } else if payload.subtitles.count > 0 {
//            url = payload.source.url.change(scheme: Self.hlsCustomPlaylistScheme)
        } else {
            url = payload.source.url
        }

        let asset = AVURLAsset(
            url: url,
            options: ["AVURLAssetHTTPHeaderFieldsKey": headers]
        )

        super.init(asset: asset, automaticallyLoadedAssetKeys: ["duration"])
        asset.resourceLoader.setDelegate(self, queue: self.resourceQueue)
    }
}

extension VideoPlayerItem: AVAssetResourceLoaderDelegate {
    func resourceLoader(
        _ resourceLoader: AVAssetResourceLoader,
        shouldWaitForLoadingOfRequestedResource loadingRequest: AVAssetResourceLoadingRequest
    ) -> Bool {
        guard let url = loadingRequest.request.url else { return false }

        let callback: (Result<Data, Error>) -> Void = {
            switch $0 {
            case .success(let data):
                loadingRequest.dataRequest?.respond(with: data)
                loadingRequest.finishLoading()
            case .failure(let error):
                print(error.localizedDescription)
                loadingRequest.finishLoading(with: error)
            }
        }

        if payload.source.format == .mpd {
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
                handleDASHRequest(url, callback)
            }
        } else {
            handleHLSRequest(url, callback)
        }
        return true
    }
}

extension URL {
    func change(scheme: String) -> URL {
        var component = URLComponents(url: self, resolvingAgainstBaseURL: false)
        component?.scheme = scheme
        return component?.url ?? self
    }

    var recoveryScheme: URL {
        var component = URLComponents(url: self, resolvingAgainstBaseURL: false)
        component?.scheme = "https"
        return component?.url ?? self
    }
}
