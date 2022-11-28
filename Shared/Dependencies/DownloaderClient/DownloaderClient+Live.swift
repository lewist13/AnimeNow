//  DownloaderClient+Live.swift
//  Anime Now! (iOS)
//
//  Created by ErrorErrorError on 11/24/22.
//  
//

import Combine
import Foundation
import AVFoundation

extension DownloaderClient {
    static let liveValue: DownloaderClient = {
        let configuration = URLSessionConfiguration.background(withIdentifier: "downloader-client")
        let downloadStates = CurrentValueSubject<[DownloaderClient.Item : DownloaderClient.Status], Never>(.init())

        return .init(
            observe: { animeId in
                let mappablePublisher = downloadStates
                    .map { items in
                        Dictionary(
                            uniqueKeysWithValues: items
                                .filter({ $0.key.animeId == animeId })
                                .map { ($0.episodeNumber, $1) }
                        )
                    }
                    .eraseToAnyPublisher()
                
                return .init { continuation in
                    let cancellable = mappablePublisher.sink {
                        continuation.yield($0)
                    }

                    continuation.onTermination = { _ in
                        cancellable.cancel()
                    }
                }
            },
            observeFinished: {
                let mappablePublisher = downloadStates
                    .map { items in
                        items.compactMapValues {
                            if case .success(let location) = $0 {
                                return location
                            } else {
                                return nil
                            }
                        }
                    }
                    .eraseToAnyPublisher()
                
                return .init { continuation in
                    let cancellable = mappablePublisher.sink {
                        continuation.yield($0)
                    }
                    
                    continuation.onTermination = { _ in
                        cancellable.cancel()
                    }
                }
            },
            download: { item in
                Task {
                    let delegate = DownloaderDelegate({ status in
                        downloadStates.value[item] = status
                    })

                    let downloadSession = AVAssetDownloadURLSession(
                        configuration: configuration,
                        assetDownloadDelegate: delegate,
                        delegateQueue: OperationQueue.main
                    )

                    let asset = AVURLAsset(url: item.source.url)

                    let name = "\(item.animeId)-\(item.episodeNumber)"

                    let downloadTask = downloadSession.makeAssetDownloadTask(
                        asset: asset,
                        assetTitle: name,
                        assetArtworkData: nil,
                        options: nil
                    )

                    downloadTask?.resume()
                    downloadStates.value[item] = .pending
                }
            },
            remove: {
                downloadStates.value.removeValue(forKey: $0)
            }
        )
    }()
}

final class DownloaderDelegate: NSObject, AVAssetDownloadDelegate {
    let callback: (DownloaderClient.Status) -> Void

    init(
        _ callback: @escaping (DownloaderClient.Status) -> Void
    ) {
        self.callback = callback
    }

    func urlSession(_ session: URLSession, assetDownloadTask: AVAssetDownloadTask, didLoad timeRange: CMTimeRange, totalTimeRangesLoaded loadedTimeRanges: [NSValue], timeRangeExpectedToLoad: CMTimeRange) {
        callback(
            .downloading(
                progress: (loadedTimeRanges.reduce(0.0) { $0 + $1.timeRangeValue.duration.seconds }) / timeRangeExpectedToLoad.duration.seconds
            )
        )
    }

    func urlSession(_ session: URLSession, assetDownloadTask: AVAssetDownloadTask, didFinishDownloadingTo location: URL) {
        callback(
            .success(location: location)
        )
    }

    func urlSession(_ session: URLSession, didBecomeInvalidWithError error: Error?) {
        if error != nil {
            callback(.failed)
        }
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if error != nil {
            callback(.failed)
        }
    }
}
