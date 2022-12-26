//  VideoPlayerClient.swift
//  VideoPlayerClient
//
//  Created by ErrorErrorError on 12/23/22.
//

import Foundation
import AVFoundation
import ComposableArchitecture

public struct VideoPlayerClient {
    public let status: () -> AsyncStream<Status>
    public let progress: () -> AsyncStream<Double>
    public let execute: (Action) async -> Void
    public let player: () -> AVPlayer
}

public extension VideoPlayerClient {
    typealias VideoGravity = AVLayerVideoGravity

    enum Status: Equatable {

        /// Idle
        case idle

        /// From the first load to get the first frame of the video
        case loading

        /// Player can start playing
        case loaded

        /// Waiting for the next couple of frames to load
        case buffering

        /// Playing now
        case playing

        /// Video paused
        case paused

        /// Finished Playing
        case finished

        /// An error occurred and cannot continue playing
        case error
    }

    enum Action: Equatable {

        /// Play Item

        case play(URL, Metadata? = nil)

        /// Resume  Video
        case resume

        /// Pause Video
        case pause

        /// Change Progress
        case seekTo(Double)

        /// Change Volume
        case volume(Double)

        /// Clear Video Player
        case clear
    }

    struct Metadata: Equatable {
        let videoTitle: String
        let videoAuthor: String
        var thumbnail: URL? = nil

        public init(
            videoTitle: String,
            videoAuthor: String,
            thumbnail: URL? = nil
        ) {
            self.videoTitle = videoTitle
            self.videoAuthor = videoAuthor
            self.thumbnail = thumbnail
        }
    }
}

extension VideoPlayerClient: @unchecked Sendable { }

extension VideoPlayerClient: DependencyKey { }

public extension DependencyValues {
    var videoPlayerClient: VideoPlayerClient {
        get { self[VideoPlayerClient.self] }
        set { self[VideoPlayerClient.self] = newValue }
    }
}
