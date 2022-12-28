//
//  VideoPlayerClient+Live.swift
//  VideoPlayerClient
//
//  Created by ErrorErrorError on 12/23/22.
//  

import AVKit
import Combine
import AVFAudio
import Foundation
import Kingfisher
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

    #if os(iOS)
    private let session = AVAudioSession.sharedInstance()
    #endif

    private var playerItemCancellables = Set<AnyCancellable>()
    private var cancellables = Set<AnyCancellable>()
    private var timerObserver: Any?

    private let nowPlayingOperationQueue = OperationQueue()

    private var status: VideoPlayerClient.Status {
        get { statusPublisher.value }
        set {
            if statusPublisher.value != newValue {
                statusPublisher.value = newValue
            }
        }
    }

    init() {
        configureInit()
    }

    private func configureInit() {
        player.automaticallyWaitsToMinimizeStalling = true
        player.preventsDisplaySleepDuringVideoPlayback = true
        player.actionAtItemEnd = .pause

        #if os(iOS)
        try? session.setCategory(
            .playback,
            mode: .moviePlayback,
            policy: .longFormVideo
        )
        #endif

        NotificationCenter.default.publisher(for: .AVPlayerItemDidPlayToEndTime)
            .compactMap { $0.object as? AVPlayerItem }
            .filter { [unowned self] item in item == self.player.currentItem }
            .sink { [unowned self] _ in
                self.updateStatus(.finished)
            }
            .store(in: &cancellables)

        /// Observe Player

        player.publisher(
            for: \.timeControlStatus
        )
        .dropFirst()
        .sink { [unowned self] status in
            switch status {
            case .waitingToPlayAtSpecifiedRate:
                if let waiting = player.reasonForWaitingToPlay {
                    switch waiting {
                    case .noItemToPlay:
                        self.updateStatus(.idle)

                    case .toMinimizeStalls:
                        self.updateStatus(.playback(.buffering))

                    default:
                        break
                    }
                }

            case .paused:
                self.updateStatus(.playback(.paused))

            case .playing:
                self.updateStatus(.playback(.playing))

            default:
                break
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
                seconds: 1,
                preferredTimescale: 1
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
            updateStatus(.idle)
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
                self.updateStatus(.idle)

            case .readyToPlay:
                // TODO: Test if duration is updated
//                self.updateStatus(.loaded(duration: playerItem.totalDuration))
                break

            case .failed:
                self.updateStatus(.error)

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
                self.updateStatus(.playback(.buffering))
            }
        }
        .store(in: &playerItemCancellables)

        playerItem.publisher(
            for: \.isPlaybackLikelyToKeepUp
        )
        .dropFirst()
        .sink { [unowned self] canKeepUp in
            if canKeepUp && self.status == .playback(.buffering) {
                self.updateStatus(.playback(self.player.rate > 0 ? .playing : .paused))
            }
        }
        .store(in: &playerItemCancellables)

        playerItem.publisher(for: \.duration)
            .dropFirst()
            .sink { [unowned self] duration in
                if duration.isValid && duration.seconds > 0.0 {
                    self.updateStatus(.loaded(duration: duration.seconds))
                }
            }
            .store(in: &playerItemCancellables)
    }

    private func updateNowPlaying(_ metadata: VideoPlayerClient.Metadata? = nil) {
        nowPlayingOperationQueue.addOperation { [unowned self] in
            let nowPlayingInfoCenter = MPNowPlayingInfoCenter.default()
            var nowPlayingInfo = nowPlayingInfoCenter.nowPlayingInfo ?? [:]

            nowPlayingInfo[MPMediaItemPropertyPlaybackDuration] = self.player.currentItem?.totalDuration ?? self.player.totalDuration
            nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = self.player.currentItem?.currentDuration ?? self.player.currentDuration
            nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = self.player.rate

            if let metadata {
                nowPlayingInfo[MPMediaItemPropertyTitle] = metadata.videoTitle
                nowPlayingInfo[MPMediaItemPropertyAlbumTitle] = metadata.videoAuthor
                if let imageURL = metadata.thumbnail,
                   let image = ImageCache.default.retrieveImageInMemoryCache(
                    forKey: imageURL.absoluteString,
                    options: .none
                   ) {
                    nowPlayingInfo[MPMediaItemPropertyArtwork] = MPMediaItemArtwork(
                        boundsSize: image.size,
                        requestHandler: { size in
                            image
                        }
                    )
                } else {
                    nowPlayingInfo[MPMediaItemPropertyArtwork] = nil
                }
            }

            nowPlayingInfoCenter.nowPlayingInfo = nowPlayingInfo

            #if os(macOS)
            switch self.status {
            case .idle:
                MPNowPlayingInfoCenter.default().playbackState = .stopped
            case .loading:
                MPNowPlayingInfoCenter.default().playbackState = .playing
            case .loaded:
                MPNowPlayingInfoCenter.default().playbackState = .playing
            case .playback(.buffering):
                MPNowPlayingInfoCenter.default().playbackState = .playing
            case .playback(.playing):
                MPNowPlayingInfoCenter.default().playbackState = .playing
            case .playback(.paused):
                MPNowPlayingInfoCenter.default().playbackState = .paused
            case .error:
                MPNowPlayingInfoCenter.default().playbackState = .unknown
            case .finished:
                MPNowPlayingInfoCenter.default().playbackState = .paused
            }
            #endif
        }
    }

    func handle(_ action: VideoPlayerClient.Action) {
        switch action {
        case .play(let url, let metadata):
            let asset = AVURLAsset(url: url)
            let playerItem = AVPlayerItem(asset: asset)
            player.replaceCurrentItem(with: playerItem)
            #if os(iOS)
            try? session.setActive(true)
            #endif
            updateStatus(.loading)
            updateNowPlaying(metadata)

        case .resume:
            if status.canChangePlayback {
                player.play()
            }

        case .pause:
            if status.canChangePlayback {
                player.pause()
            }

        case .seekTo(let progress):
            if status.canChangePlayback {
                let time = CMTime(
                    seconds: round(progress * player.totalDuration),
                    preferredTimescale: 1
                )
                player.seek(to: time, toleranceBefore: .zero, toleranceAfter: .zero)
            }

        case .volume(let volume):
            player.volume = Float(volume)

        case .clear:
            player.pause()
            player.removeAllItems()
            playerItemCancellables.removeAll()
            updateStatus(.idle)
            #if os(iOS)
            try? session.setActive(false, options: .notifyOthersOnDeactivation)
            #endif
            MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
            #if os(macOS)
            MPNowPlayingInfoCenter.default().playbackState = .unknown
            #endif
        }
    }

    private func updateStatus(_ newStatus: VideoPlayerClient.Status) {
        let oldStatus = self.status

        guard oldStatus != newStatus else { return }

        guard newStatus != .idle && newStatus != .error else {
            self.status = newStatus
            return
        }

        switch (oldStatus, newStatus) {
        case (.idle, .loading), (.idle, .loaded):
            self.status = newStatus

        case (.loading, .loaded):
            self.status = newStatus

        case (.loaded, .playback), (.loaded, .loaded):
            self.status = newStatus

        case (.playback, .finished), (.playback, .playback):
            self.status = newStatus

        case (.finished, .playback(.playing)), (.finished, .playback(.buffering)):
            self.status = newStatus

        default:
            break
        }
    }
}

extension VideoPlayerClient.Status {
    internal var canChangePlayback: Bool {
        switch self {
        case .loaded, .playback, .finished:
            return true
        default:
            return false
        }
    }
}
