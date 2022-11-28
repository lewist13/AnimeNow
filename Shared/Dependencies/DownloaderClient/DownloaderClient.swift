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
    let observe: (Anime.ID) -> AsyncStream<[Int:Status]>
    let observeFinished: () -> AsyncStream<[Item : URL]>
    let download: (Item) -> Void
    let remove: (Item) -> Void
}

extension DownloaderClient {
    enum Status: Equatable {
        case pending
        case downloading(progress: Double)
        case success(location: URL)
        case failed
    }

    struct Item: Hashable {
        let animeId: Anime.ID
        let episodeNumber: Int
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
