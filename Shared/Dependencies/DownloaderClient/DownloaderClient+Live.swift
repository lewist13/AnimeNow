////  DownloaderClient+Live.swift
//  Anime Now! (iOS)
//
//  Created by ErrorErrorError on 11/24/22.
//  
//

import Foundation
import AVFoundation

extension DownloaderClient {
    static let liveValue: DownloaderClient = {

        return .init(
            download: { url in
                .init { continuation in
                    Task {
                        let name = url.lastPathComponent
                        let configuration = URLSessionConfiguration.background(withIdentifier: name)
                        let delegate = DownloaderDelegate(continuation)
                        let downloadSession = AVAssetDownloadURLSession(
                            configuration: .default,
                            assetDownloadDelegate: delegate,
                            delegateQueue: OperationQueue.main
                        )

                        let asset = AVURLAsset(url: url)

                        // Create new AVAssetDownloadTask for the desired asset
                        let downloadTask = downloadSession.makeAssetDownloadTask(
                            asset: asset,
                            assetTitle: name,
                            assetArtworkData: nil,
                            options: nil
                        )

                        continuation.onTermination = { _ in
                            downloadTask?.cancel()
                        }

                        downloadTask?.resume()
                        continuation.yield(.downloading)
                    }
                }
            }
        )
    }()
}

class DownloaderDelegate: NSObject, AVAssetDownloadDelegate {
    let continuation: AsyncThrowingStream<DownloaderClient.Status, Error>.Continuation

    init(
        _ continuation: AsyncThrowingStream<DownloaderClient.Status, Error>.Continuation
    ) {
        self.continuation = continuation
    }

    func urlSession(_ session: URLSession, assetDownloadTask: AVAssetDownloadTask, didFinishDownloadingTo location: URL) {
        continuation.yield(.success(location))
    }

    func urlSession(_ session: URLSession, didBecomeInvalidWithError error: Error?) {
        continuation.finish(throwing: error)
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        continuation.finish(throwing: error)
    }
}
