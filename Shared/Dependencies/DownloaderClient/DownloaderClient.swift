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
    let onFinish: () -> AsyncStream<(Request, URL)>
    let observe: (Anime.ID) -> AsyncStream<[Int : Status]>
    let download: (Request) -> Void
    let delete: (URL) async -> Void
    let observeCount: () -> AsyncStream<Int>
    let cancelDownload: (Anime.ID, Int) -> Void
}

extension DownloaderClient {
    enum Status: Equatable {
        case pending
        case downloading(progress: Double)
        case success(location: URL)
        case failed
    }

    struct Request {
        let anime: any AnimeRepresentable
        let episode: any EpisodeRepresentable
        let source: Source
    }
}

extension DownloaderClient: DependencyKey {}

extension DependencyValues {
    var downloaderClient: DownloaderClient {
        get { self[DownloaderClient.self] }
        set { self[DownloaderClient.self] = newValue }
    }
}
