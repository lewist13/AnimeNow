//  DownloaderClient+V2.swift
//  Anime Now!
//
//  Created by ErrorErrorError on 12/9/22.
//

import Logger
import Combine
import Utilities
import Foundation
import AVFoundation

extension DownloaderClient {
    private struct TaskData {
        let request: Request
        var status: Status
    }

    private static let configuration = URLSessionConfiguration.background(
        withIdentifier: (Bundle.main.bundleIdentifier ?? "unknown") + ".downloader-client"
    )

    private static let storeURL: URL? = {
        let directories = FileManager.default.urls(
            for: .cachesDirectory,
            in: .userDomainMask
        )
        return directories.first?.appendingPathComponent("AnimeNowDownloads", conformingTo: .data)
    }()

    private static var videoStorageDirectoryURL: URL? {
        guard var cachesDir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first else { return nil }
        cachesDir = cachesDir.appendingPathComponent("com.apple.nsurlsessiond", conformingTo: .directory)
        cachesDir = cachesDir.appendingPathComponent("Downloads", conformingTo: .directory)
        cachesDir = cachesDir.appendingPathComponent(Bundle.main.bundleIdentifier ?? "", conformingTo: .directory)
        return cachesDir
    }

    private static let downloadedContent: CurrentValueSubject<Set<AnimeStorage>, Never> = .init([])
    private static let downloadsStatus = CurrentValueSubject<[URLSessionTask.ID : TaskData], Never>([:])

    private static let downloadedContentQueue = OperationQueue()

    public static let liveValue: DownloaderClient = {
        fetchFromDisk()

        let delegate = DownloaderDelegate { task, status in
            if let data = downloadsStatus.value[task] {
                if case .downloaded(let location) = status {
                    syncDownloadedEpisodeToDisk(location: location, data.request)
                    downloadsStatus.value[task] = nil
                } else {
                    downloadsStatus.value[task]?.status = status
                }
            } else {
                if case .downloaded(let location) = status {
                    try? FileManager.default.removeItem(at: location)
                }
            }
        }

        let downloadSession = AVAssetDownloadURLSession(
            configuration: configuration,
            assetDownloadDelegate: delegate,
            delegateQueue: OperationQueue.main
        )

        return .init { animeId in
            let mappablePublisher = Publishers.CombineLatest(downloadedContent, downloadsStatus.map(\.values))
                .map({ downloaded, downloads in
                    var allAnimes = downloaded

                    for task in downloads {
                        if allAnimes[id: task.request.anime.id] != nil {
                            allAnimes[id: task.request.anime.id]?.episodes.update(
                                .init(
                                    number: task.request.episode.number,
                                    title: task.request.episode.title,
                                    thumbnail: task.request.episode.thumbnail,
                                    isFiller: task.request.episode.isFiller,
                                    status: task.status
                                )
                            )
                        } else {
                            allAnimes[id: task.request.anime.id] = .init(
                                id: task.request.anime.id,
                                title: task.request.anime.title,
                                format: task.request.anime.format,
                                posterImage: task.request.anime.posterImage,
                                episodes: [
                                    .init(
                                        number: task.request.episode.number,
                                        title: task.request.episode.title,
                                        thumbnail: task.request.episode.thumbnail,
                                        isFiller: task.request.episode.isFiller,
                                        status: task.status
                                    )
                                ]
                            )
                        }
                    }

                    if let animeId {
                        return allAnimes.filter {
                            animeId == $0.id
                        }
                    } else {
                        return allAnimes
                    }
                })
                .eraseToAnyPublisher()

            return .init { continuation in
                let cancellable = mappablePublisher.sink {
                    continuation.yield($0)
                }

                continuation.onTermination = { _ in
                    cancellable.cancel()
                }
            }
        } download: { request in
            let asset = AVURLAsset(url: request.source.url)
            let name = "\(request.anime.title) - Episode \(request.episode.number)"

            guard let downloadTask = downloadSession.makeAssetDownloadTask(
                asset: asset,
                assetTitle: name,
                assetArtworkData: nil,
                options: nil
            ) else {
                return
            }

            downloadsStatus.value[downloadTask.taskIdentifier] = .init(request: request, status: .pending)

            downloadTask.resume()
        } delete: { animeId, episodeNumber in
            downloadedContentQueue.addOperation {
                if var anime = downloadedContent.value.first(where: { $0.id == animeId }) {
                    if let episode = anime.episodes.first(where: { $0.number == episodeNumber }) {
                        if case .offline(let url) = episode.links.first {
                            try? FileManager.default.removeItem(at: url)
                        }

                        anime.episodes.remove(episode)
                    }

                    if anime.episodes.count > 0 {
                        downloadedContent.value.update(anime)
                    } else {
                        downloadedContent.value[id: anime.id] = nil
                    }

                    syncToDisk()
                }
            }
        } count: {
            return .init { continuation in
                let cancellable = downloadsStatus
                    .map {
                        $0.filter { element in
                            switch element.value.status {
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
        } cancel: { animeId, episodeNumber in
            let downloads = downloadsStatus.value.filter { $0.value.request.anime.id == animeId && $0.value.request.episode.number == episodeNumber }.map(\.key)
            let tasks = await downloadSession.allTasks

            for task in tasks {
                if downloads.contains(task.taskIdentifier) {
                    downloadsStatus.value[task.taskIdentifier] = nil
                    task.cancel()
                }
            }
        } retry: { animeId, episodeNumber in
            let downloads = downloadsStatus.value.filter { $0.value.request.anime.id == animeId && $0.value.request.episode.number == episodeNumber }.map(\.key)
            let tasks = await downloadSession.allTasks

            for task in tasks {
                if downloads.contains(task.taskIdentifier) {
                    downloadsStatus.value[task.taskIdentifier]?.status = .pending
                    task.resume()
                }
            }
        } reset: {
            Task {
                if let videoStorageDirectoryURL {
                    let contents = try? FileManager.default.contentsOfDirectory(
                        at: videoStorageDirectoryURL,
                        includingPropertiesForKeys: nil
                    )

                    for content in contents ?? [] {
                        try? FileManager.default.removeItem(at: content)
                    }
                }

                downloadedContent.value.removeAll()

                downloadedContentQueue.addOperation {
                    syncToDisk()
                }
            }
        }
    }()

    private static func fetchFromDisk() {
        guard let storeURL else { return }
        do {
            let savedData = try Data(contentsOf: storeURL)
            downloadedContent.value = try savedData.toObject() ?? .init()
        } catch {
            Logger.log(.error, error.localizedDescription)
        }
    }

    private static func syncDownloadedEpisodeToDisk(
        location: URL,
        _ request: Request
    ) {
        downloadedContentQueue.addOperation {
            var anime = downloadedContent.value.first(where: { $0.id == request.anime.id }) ?? .init(
                id: request.anime.id,
                title: request.anime.title,
                format: request.anime.format,
                posterImage: request.anime.posterImage,
                episodes: .init()
            )

            anime.episodes.update(
                .init(
                    number: request.episode.number,
                    title: request.episode.title,
                    thumbnail: request.episode.thumbnail,
                    isFiller: request.episode.isFiller,
                    status: .downloaded(location: location)
                )
            )

            downloadedContent.value.update(anime)

            syncToDisk()
        }
    }

    private static func syncToDisk() {
        guard let storeURL else { return }

        do {
            let data = try downloadedContent.value.toData()
            try data.write(to: storeURL)
        } catch {
            Logger.log(.error, error.localizedDescription)
        }
    }

    private static func removeUnusedVideos() {
        
    }
}

fileprivate class DownloaderDelegate: NSObject, AVAssetDownloadDelegate {
    let callback: (Int, DownloaderClient.Status) -> Void

    init(_ callback: @escaping (Int, DownloaderClient.Status) -> Void) {
        self.callback = callback
    }

    func urlSession(_ session: URLSession, assetDownloadTask: AVAssetDownloadTask, didLoad timeRange: CMTimeRange, totalTimeRangesLoaded loadedTimeRanges: [NSValue], timeRangeExpectedToLoad: CMTimeRange) {
        callback(
            assetDownloadTask.taskIdentifier,
            .downloading(
                progress: (loadedTimeRanges.reduce(0.0) { $0 + $1.timeRangeValue.duration.seconds }) / timeRangeExpectedToLoad.duration.seconds
            )
        )
    }

    func urlSession(_ session: URLSession, assetDownloadTask: AVAssetDownloadTask, didFinishDownloadingTo location: URL) {
        callback(
            assetDownloadTask.taskIdentifier,
            .downloaded(location: location)
        )
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if error != nil {
            callback(
                task.taskIdentifier,
                .failed
            )
        }
    }
}

extension URLSessionTask: Identifiable {
    public var id: Int {
        taskIdentifier
    }
}
