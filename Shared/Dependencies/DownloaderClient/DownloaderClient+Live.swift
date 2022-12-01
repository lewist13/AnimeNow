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
    private static let configuration = URLSessionConfiguration.background(
        withIdentifier: (Bundle.main.bundleIdentifier ?? "unknown") + ".downloader-client"
    )

    private static var contentPool = CurrentValueSubject<[AVAssetDownloadTask: Request], Never>(.init())
    private static let downloadStates = CurrentValueSubject<[AVAssetDownloadTask : Status], Never>(.init())
    private static let downloadFinishedCallback = CurrentValueSubject<(Request, URL)?, Never>(nil)

    static let liveValue: DownloaderClient = {
        let delegate = DownloaderDelegate { task, status in
            if case .success(let location) = status {
                if let request = contentPool.value[task] {
                    downloadFinishedCallback.send((request, location))
                }
                contentPool.value[task] = nil
                downloadStates.value[task] = nil
            } else {
                downloadStates.value[task] = status
            }
        }

        let downloadSession = AVAssetDownloadURLSession(
            configuration: configuration,
            assetDownloadDelegate: delegate,
            delegateQueue: OperationQueue.main
        )

        return .init(
            onFinish: {
                return .init { continuation in
                    let cancellable = downloadFinishedCallback.compactMap { $0 } .sink {
                        continuation.yield($0)
                    }

                    continuation.onTermination = { _ in
                        cancellable.cancel()
                    }
                }
            },
            observe: { animeId in
                let mappablePublisher = Publishers.CombineLatest(downloadStates, contentPool)
                    .map { downloads, content in
                        Dictionary(
                            uniqueKeysWithValues: downloads.compactMap({ key, value -> (Int, Status)? in
                                guard let item = content[key], item.anime.id == animeId else {
                                    return nil
                                }
                                return (item.episode.number, value)
                            })
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
            download: { item in
                let asset = AVURLAsset(url: item.source.url)

                let name = "\(item.anime.title) - Episode \(item.episode.number)"

                guard let downloadTask = downloadSession.makeAssetDownloadTask(
                    asset: asset,
                    assetTitle: name,
                    assetArtworkData: nil,
                    options: nil
                ) else {
                    return
                }

                contentPool.value[downloadTask] = item
                downloadStates.value[downloadTask] = .pending

                downloadTask.resume()
            },
            delete: { url in
                Task {
                    if FileManager.default.fileExists(atPath: url.absoluteString) {
                        try FileManager.default.removeItem(at: url)
                    }
                }
            },
            observeCount: {
                return .init { continuation in
                    let cancellable = downloadStates
                        .map {
                            $0.filter { element in
                                switch element.value {
                                case .pending, .downloading:
                                    return true
                                default:
                                    return false
                                }
                            }
                            .count
                        }
                        .sink {
                        continuation.yield($0)
                    }

                    continuation.onTermination = { _ in
                        cancellable.cancel()
                    }
                }
            },
            cancelDownload: { animeId, episodeNumber in
                if let (task, _) = contentPool.value.first(
                    where: { $0.value.anime.id == animeId && $0.value.episode.number == episodeNumber }
                ) {
                    task.cancel()
                    contentPool.value[task] = nil
                    downloadStates.value[task] = nil
                }
            }
        )
    }()
}

fileprivate class DownloaderDelegate: NSObject, AVAssetDownloadDelegate {
    let callback: (AVAssetDownloadTask, DownloaderClient.Status) -> Void

    init(_ callback: @escaping (AVAssetDownloadTask, DownloaderClient.Status) -> Void) {
        self.callback = callback
    }

    func urlSession(_ session: URLSession, assetDownloadTask: AVAssetDownloadTask, didLoad timeRange: CMTimeRange, totalTimeRangesLoaded loadedTimeRanges: [NSValue], timeRangeExpectedToLoad: CMTimeRange) {
        callback(
            assetDownloadTask,
            .downloading(
                progress: (loadedTimeRanges.reduce(0.0) { $0 + $1.timeRangeValue.duration.seconds }) / timeRangeExpectedToLoad.duration.seconds
            )
        )
    }

    func urlSession(_ session: URLSession, assetDownloadTask: AVAssetDownloadTask, didFinishDownloadingTo location: URL) {
        callback(
            assetDownloadTask,
            .success(location: location)
        )
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if error != nil {
            callback(
                task as! AVAssetDownloadTask,
                .failed
            )
        }
    }
}
