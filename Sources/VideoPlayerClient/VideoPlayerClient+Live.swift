//
//  VideoPlayerClient+Live.swift
//  VideoPlayerClient
//
//  Created by ErrorErrorError on 12/23/22.
//  

import AVKit
import Combine
import Foundation
import MediaPlayer
import AVFoundation
import AnyPublisherStream

extension VideoPlayerClient {
    public static let liveValue: Self = {
        let wrapper = PlayerWrapper()

        return .init(
            status: { wrapper.statusPublisher.stream },
            progress: {
                .init { continuation in
                    let timerObserver = wrapper.player.addPeriodicTimeObserver(
                        forInterval: .init(
                            seconds: 0.25,
                            preferredTimescale: 60
                        ),
                        queue: .main
                    ) { _ in
                        continuation.yield(wrapper.player.playProgress)
                    }

                    continuation.onTermination = { _ in
                        wrapper.player.removeTimeObserver(timerObserver)
                    }
                }
            },
            execute: wrapper.handle,
            player: { wrapper.player }
        )
    }()
}

private class PlayerWrapper {
    let player = AVQueuePlayer()
    let statusPublisher = CurrentValueSubject<VideoPlayerClient.Status, Never>(.idle)

    private var playerItemCancellables = Set<AnyCancellable>()
    private var cancellables = Set<AnyCancellable>()
    private var timerObserver: Any?

    private var status: VideoPlayerClient.Status {
        get { statusPublisher.value }
        set { statusPublisher.value = newValue }
    }

    init() {
        configureInit()
    }

    private func configureInit() {
        player.automaticallyWaitsToMinimizeStalling = true
        player.preventsDisplaySleepDuringVideoPlayback = true

        NotificationCenter.default.publisher(for: .AVPlayerItemDidPlayToEndTime)
            .compactMap { $0.object as? AVPlayerItem }
            .filter { [unowned self] item in item == self.player.currentItem }
            .sink { [unowned self] _ in
                self.status = .finished
            }
            .store(in: &cancellables)

        /// Observe Player

        player.publisher(
            for: \.timeControlStatus
        )
        .dropFirst()
        .filter { [unowned self] _ in self.status != .idle }
        .sink { [unowned self] status in
            switch status {
            case .waitingToPlayAtSpecifiedRate:
                if let waiting = player.reasonForWaitingToPlay {
                    switch waiting {
                    case .noItemToPlay:
                        self.status = .idle

                    case .toMinimizeStalls:
                        self.status = .buffering
                    default:
                        break
                    }
                }

            case .paused:
                self.status = .paused

            case .playing:
                self.status = .playing

            default:
                self.status = .loading
            }
        }
        .store(in: &cancellables)

        player.publisher(
            for: \.currentItem
        )
        .sink { [unowned self] item in
            self.observe(playerItem: item)
        }
        .store(in: &cancellables)

        timerObserver = player.addPeriodicTimeObserver(
            forInterval: .init(
                seconds: 0.25,
                preferredTimescale: 60
            ),
            queue: .main
        ) { [unowned self] time in
            self.updateNowPlaying()
        }

        let commandCenter = MPRemoteCommandCenter.shared()
        commandCenter.playCommand.addTarget { [weak self] event in
            guard let `self` = self else { return .commandFailed }

            if self.player.rate == 0.0 {
                self.player.play()
                return .success
            }

            return .commandFailed
        }

        commandCenter.pauseCommand.addTarget { [weak self] event in
            guard let `self` = self else { return .commandFailed }
            if self.player.rate > 0 {
                self.player.pause()
                return .success
            }

            return .commandFailed
        }

        commandCenter.changePlaybackPositionCommand.addTarget { [weak self] event in
            guard let event = event as? MPChangePlaybackPositionCommandEvent else {
                return .commandFailed
            }

            guard let `self` = self else { return .commandFailed }

            if self.player.totalDuration > 0.0 {
                let time = CMTime(seconds: event.positionTime, preferredTimescale: 1)
                self.player.seek(to: time)
                return .success
            }

            return .commandFailed
        }

        commandCenter.skipForwardCommand.addTarget { [weak self] event in
            guard let event = event as? MPSkipIntervalCommandEvent else {
                return .commandFailed
            }

            guard let `self` = self else { return .commandFailed }

            if self.player.totalDuration > 0.0 {
                let time = CMTime(
                    seconds: min(self.player.currentDuration + event.interval, self.player.totalDuration),
                    preferredTimescale: 1
                )
                self.player.seek(to: time)
                return .success
            }

            return .commandFailed
        }

        commandCenter.skipBackwardCommand.addTarget { [weak self] event in
            guard let event = event as? MPSkipIntervalCommandEvent else {
                return .commandFailed
            }

            guard let `self` = self else { return .commandFailed }

            if self.player.totalDuration > 0.0 {
                let time = CMTime(
                    seconds: max(self.player.currentDuration - event.interval, 0.0),
                    preferredTimescale: 1
                )
                self.player.seek(to: time)
                return .success
            }

            return .commandFailed
        }
    }

    private func observe(playerItem: AVPlayerItem?) {
        guard let playerItem = playerItem else {
            playerItemCancellables.removeAll()
            self.status = .idle
            return
        }

        playerItem.publisher(
            for: \.status
        )
        .removeDuplicates()
        .dropFirst()
        .sink { [unowned self] status in
            switch status {
            case .unknown:
                self.status = .idle

            case .readyToPlay:
                self.status = .loaded

            case .failed:
                self.status = .error

            default:
                break
            }
        }
        .store(in: &playerItemCancellables)

        playerItem.publisher(
            for: \.isPlaybackBufferEmpty
        )
        .dropFirst()
        .sink { [unowned self] bufferEmpty in
            if bufferEmpty {
                self.status = .buffering
            }
        }
        .store(in: &playerItemCancellables)

        playerItem.publisher(
            for: \.isPlaybackLikelyToKeepUp
        )
        .dropFirst()
        .sink { [unowned self] canKeepUp in
            if canKeepUp && self.status == .buffering {
                if self.player.rate > 0 {
                    self.status = .playing
                } else {
                    self.status = .paused
                }
            }
        }
        .store(in: &playerItemCancellables)
    }

    private func updateNowPlaying(_ item: VideoPlayerClient.Metadata? = nil) {
        let nowPlayingInfoCenter = MPNowPlayingInfoCenter.default()
        var nowPlayingInfo = nowPlayingInfoCenter.nowPlayingInfo ?? [:]

        nowPlayingInfo[MPMediaItemPropertyPlaybackDuration] = self.player.totalDuration
        nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = self.player.currentDuration
        nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = self.player.rate

        if let item {
            nowPlayingInfo[MPMediaItemPropertyTitle] = item.videoTitle
            nowPlayingInfo[MPMediaItemPropertyAlbumTitle] = item.videoAuthor
//            if let imageURL = item.thumbnail,
//               let image = ImageCache.default.retrieveImageInMemoryCache(forKey: imageURL.absoluteString, options: .none) {
//                nowPlayingInfo[MPMediaItemPropertyArtwork] = MPMediaItemArtwork(
//                    boundsSize: image.size,
//                    requestHandler: { size in
//                        image
//                    }
//                )
//            } else {
//                nowPlayingInfo[MPMediaItemPropertyArtwork] = nil
//            }
        }

        nowPlayingInfoCenter.nowPlayingInfo = nowPlayingInfo

        #if os(macOS)
        switch self.status {
        case .idle:
            MPNowPlayingInfoCenter.default().playbackState = .unknown
        case .loading:
            MPNowPlayingInfoCenter.default().playbackState = .unknown
        case .buffering:
            MPNowPlayingInfoCenter.default().playbackState = .stopped
        case .loaded:
            MPNowPlayingInfoCenter.default().playbackState = .unknown
        case .playing:
            MPNowPlayingInfoCenter.default().playbackState = .playing
        case .paused:
            MPNowPlayingInfoCenter.default().playbackState = .paused
        case .error:
            MPNowPlayingInfoCenter.default().playbackState = .unknown
        case .finished:
            MPNowPlayingInfoCenter.default().playbackState = .unknown
        }
        #endif
    }

    func handle(_ action: VideoPlayerClient.Action) {
        switch action {
        case .play(let url, let metadata):
            let asset = AVURLAsset(url: url)
            let playerItem = AVPlayerItem(asset: asset)
            player.replaceCurrentItem(with: playerItem)
            statusPublisher.value = .loading
            updateNowPlaying(metadata)

        case .resume:
            player.play()

        case .pause:
            player.pause()

        case .seekTo(let progress):
            let time = CMTime(
                seconds: round(progress * player.totalDuration),
                preferredTimescale: 1
            )
            player.seek(to: time, toleranceBefore: .zero, toleranceAfter: .zero)

        case .volume(let volume):
            player.volume = Float(volume)

        case .clear:
            player.removeAllItems()
            playerItemCancellables.removeAll()
            statusPublisher.value = .idle
            MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
            MPNowPlayingInfoCenter.default().playbackState = .unknown
        }
    }
}
