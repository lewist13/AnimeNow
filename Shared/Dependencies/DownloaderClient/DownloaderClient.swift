////  DownloaderClient.swift
//  Anime Now! (iOS)
//
//  Created by ErrorErrorError on 11/24/22.
//  
//

import Foundation
import ComposableArchitecture

struct DownloaderClient {
    let download: (URL) -> AsyncThrowingStream<Status, Error>
}

extension DownloaderClient {
    enum Status: Equatable {
        case success(URL)
        case downloading
    }
}

extension DownloaderClient: DependencyKey {}

extension DependencyValues {
    var downloaderClient: DownloaderClient {
        get { self[DownloaderClient.self] }
        set { self[DownloaderClient.self] = newValue }
    }
}
