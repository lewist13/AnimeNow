//  DownloaderClient.swift
//  Anime Now! (iOS)
//
//  Created by ErrorErrorError on 11/24/22.
//  
//

import Foundation
import Combine
import ComposableArchitecture

struct DownloaderClient {
    let observe: (Anime.ID?) -> AsyncStream<Set<AnimeStorage>>
    let download: (Request) -> Void
    let delete: (Anime.ID, Int) async -> Void
    let count: () -> AsyncStream<Int>
    let cancel: (Anime.ID, Int) async -> Void
    let retry: (Anime.ID, Int) async -> Void
}

extension DownloaderClient {
    enum Status: Hashable, Codable {
        case pending
        case downloading(progress: Double)
        case downloaded(location: URL)
        case failed

        var canCancelDownload: Bool {
            switch self {
            case .pending, .downloading:
                return true
            default:
                return false
            }
        }
    }

    struct Request {
        let anime: any AnimeRepresentable
        let episode: any EpisodeRepresentable
        let source: Source
    }

    struct AnimeStorage: AnimeRepresentable, Codable {
        let id: Int
        var malId: Int? { nil }
        let title: String
        let format: Anime.Format
        let posterImage: [ImageSize]
        var episodes: Set<EpisodeStorage>
    }

    struct EpisodeStorage: EpisodeRepresentable, Codable {
        var id: Int { number }
        let number: Int
        let title: String
        let thumbnail: ImageSize?
        var isFiller: Bool

        var status: Status

        var providers: [Provider] {
            switch status {
            case .downloaded(location: let url):
                return [.offline(url: url)]
            default:
                return []
            }
        }
    }
}

extension DownloaderClient.EpisodeStorage {
    var isDownloading: Bool {
        switch status {
        case .downloading:
            return true
        default:
            return false
        }
    }
}

extension DownloaderClient.AnimeStorage {
    var downloadingCount: Int {
        episodes.filter(\.isDownloading).count
    }

    var downloadingProgress: Double {
        episodes.filter(\.isDownloading).reduce(0.0) { partialResult, episode in
            if case .downloading(let progress) = episode.status {
                return partialResult + progress
            } else {
                return partialResult
            }
        } / max(Double(downloadingCount), 1.0)
        
    }
}

extension DownloaderClient.EpisodeStorage {
    var fileExists: Bool {
        if case .downloaded(let location) = status {
            return FileManager.default.fileExists(atPath: location.path)
        }
        return false
    }
}

extension DownloaderClient: DependencyKey { }

extension DependencyValues {
    var downloaderClient: DownloaderClient {
        get { self[DownloaderClient.self] }
        set { self[DownloaderClient.self] = newValue }
    }
}
