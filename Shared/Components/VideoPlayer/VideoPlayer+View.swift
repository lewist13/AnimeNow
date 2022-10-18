//
//  VideoPlayer+View.swift
//  Anime Now!
//
//  Created by ErrorErrorError on 10/12/22.
//

#if os(iOS)
import UIKit
#else
import AppKit
#endif

import Combine
import AVFoundation

extension VideoPlayer {
    class PlayerView: PlatformView {
        var player = AVQueuePlayer()
        var playerLayer: AVPlayerLayer { layer as! AVPlayerLayer }

        #if os(iOS)
        override class var layerClass: AnyClass { AVPlayerLayer.self }
        #else
        override func makeBackingLayer() -> CALayer { AVPlayerLayer() }
        #endif

        /// Muted
        open var isMuted: Bool {
            get { return player.isMuted }
            set { player.isMuted = newValue }
        }

        /// Volume
        var volume: Double {
            get { return Double(player.volume) }
            set { player.volume = Float(newValue) }
        }

        /// Play progress , value range 0-1.
        var playProgress: Double {
            return player.playProgress
        }

        /// Buffered progress, value range 0-1.
        var bufferProgress: Double {
            return player.bufferProgress
        }

        /// Buffered length in seconds.
        var currentBufferDuration: Double {
            return player.currentBufferDuration
        }

        /// Played length in seconds.
        var currentDuration: Double {
            return player.currentDuration
        }

        /// Total video duration in seconds.
        var totalDuration: Double {
            return player.totalDuration
        }

        private(set) var status: Status = .idle {
            didSet { updateStatusCallback(status, oldValue) }
        }

        /// Played to end time callback
        var playedToEndTime: (() -> Void)?

        /// Status did changed callback
        var statusDidChange: ((Status) -> Void)?

        var periodicTimeChanged: ((CMTime) -> Void)?

        private var playerItemCancellables = Set<AnyCancellable>()

        private var cancellables = Set<AnyCancellable>()

        private var timerObserver: Any?

        init() {
            super.init(frame: .zero)
            configureInit()
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        deinit {
            destroy()
        }
    }
}

extension VideoPlayer.PlayerView {
    private func configureInit() {
        NotificationCenter.default.publisher(for: .AVPlayerItemDidPlayToEndTime)
            .compactMap { $0.object as? AVPlayerItem }
            .filter { [unowned self] item in item == self.player.currentItem }
            .sink { [unowned self] _ in
                self.playedToEndTime?()
            }
            .store(in: &cancellables)

        /// Observe Player

        player.publisher(for: \.timeControlStatus)
            .sink { [unowned self] status in
                switch status {
                case .waitingToPlayAtSpecifiedRate:
                    if let waiting = player.reasonForWaitingToPlay {
                        switch waiting {
                        case .noItemToPlay:
                            self.status = .idle
                        case .toMinimizeStalls:
                            self.status = .buffering
                        case .evaluatingBufferingRate:
                            break
                        default:
                            self.status = .loading
                        }
                    } else {
                        self.status = .loading
                    }
                case .paused:
                    if self.status != .buffering {
                        self.status = .paused
                    }
                case .playing:
                    self.status = .playing
                default:
                    self.status = .loading
                }
            }
            .store(in: &cancellables)

        player.publisher(for: \.currentItem)
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
            self.periodicTimeChanged?(time)
        }

        #if os(macOS)
        self.wantsLayer = true
        #endif

        self.playerLayer.player = player
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
        .sink { [unowned self] status in
            switch status {
            case .unknown:
                self.status = .idle
            case .readyToPlay:
                self.status = .readyToPlay
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
        .sink { [unowned self] bufferEmpty in
            if bufferEmpty {
                self.status = .buffering
            }
        }
        .store(in: &playerItemCancellables)

        playerItem.publisher(
            for: \.isPlaybackLikelyToKeepUp
        )
        .sink { [unowned self] canKeepUp in
            if canKeepUp && (self.status == .loading || self.status == .readyToPlay || self.status == .buffering) {
                self.resume()
            }
        }
        .store(in: &playerItemCancellables)
    }

    private func updateStatusCallback(
        _ status: VideoPlayer.Status,
        _ previous: VideoPlayer.Status
    ) {
        guard status != previous else { return }
        statusDidChange?(status)
    }
}

extension VideoPlayer.PlayerView {
    func play(for url: URL) -> Bool {
        guard url != (player.currentItem?.asset as? AVURLAsset)?.url else { return false }
        stopAndRemoveItem()

        let asset = AVURLAsset(url: url)
        let item = AVPlayerItem(asset: asset)
        player.replaceCurrentItem(with: item)

        return true
    }

    func resume() {
        if player.currentItem != nil {
            player.play()
        }
    }

    func pause() {
        if player.currentItem != nil {
            player.pause()
        }
    }

    func seek(to time: CMTime) {
        player.seek(to: time, toleranceBefore: .zero, toleranceAfter: .zero)
    }

    func stopAndRemoveItem() {
        player.replaceCurrentItem(with: nil)
    }

    func destroy() {
        statusDidChange = nil
        periodicTimeChanged = nil

        if let timerObserver = timerObserver {
            player.removeTimeObserver(timerObserver)
            self.timerObserver = nil
        }
        stopAndRemoveItem()

        cancellables.removeAll()
        playerItemCancellables.removeAll()
    }

    func resize(_ size: AVLayerVideoGravity) {
        playerLayer.videoGravity = size
    }
}

// MARK: AVPlayerItem + Extension

public extension AVPlayerItem {
    var bufferProgress: Double {
        guard totalDuration > 0 else { return 0}
        return currentBufferDuration / totalDuration
    }
    
    var currentBufferDuration: Double {
        guard let range = loadedTimeRanges.first else { return 0 }
        return range.timeRangeValue.end.seconds
    }
    
    var currentDuration: Double {
        currentTime().seconds
    }
    
    var playProgress: Double {
        guard totalDuration > 0 else { return 0 }
        return currentDuration / totalDuration
    }

    var totalDuration: Double {
        asset.duration.seconds
    }
}

// MARK: AVPlayer + Extension

extension AVPlayer {
    var bufferProgress: Double {
        return currentItem?.bufferProgress ?? 0
    }
    
    var currentBufferDuration: Double {
        return currentItem?.currentBufferDuration ?? 0
    }
    
    var currentDuration: Double {
        return currentItem?.currentDuration ?? 0
    }

    #if !os(macOS)
    var currentImage: UIImage? {
        guard
            let playerItem = currentItem,
            let cgImage = try? AVAssetImageGenerator(asset: playerItem.asset).copyCGImage(at: currentTime(), actualTime: nil)
            else { return nil }

        return UIImage(cgImage: cgImage)
    }
    #else
    var currentImage: NSImage? {
        guard
            let playerItem = currentItem,
            let cgImage = try? AVAssetImageGenerator(asset: playerItem.asset).copyCGImage(at: currentTime(), actualTime: nil)
        else {
            return nil
        }
        let width: CGFloat = CGFloat(cgImage.width)
        let height: CGFloat = CGFloat(cgImage.height)
        return NSImage(cgImage: cgImage, size: NSMakeSize(width, height))
    }
    #endif
    
    var playProgress: Double {
        return currentItem?.playProgress ?? 0
    }
    
    var totalDuration: Double {
        return currentItem?.totalDuration ?? 0
    }
    
    convenience init(asset: AVURLAsset) {
        self.init(playerItem: AVPlayerItem(asset: asset))
    }
}

extension AVPlayerItem.Status: CustomStringConvertible, CustomDebugStringConvertible {
    public var debugDescription: String {
        description
    }

    public var description: String {
        switch self {
        case .unknown:
            return "unknown"
        case .readyToPlay:
            return "readyToPlay"
        case .failed:
            return "failed"
        @unknown default:
            return "default-unknown"
        }
    }
}

extension AVPlayer.Status: CustomStringConvertible, CustomDebugStringConvertible {
    public var debugDescription: String {
        description
    }

    public var description: String {
        switch self {
        case .unknown:
            return "unknown"
        case .readyToPlay:
            return "readyToPlay"
        case .failed:
            return "failed"
        @unknown default:
            return "default-unknown"
        }
    }
}

extension AVPlayer.TimeControlStatus: CustomStringConvertible, CustomDebugStringConvertible {
    public var debugDescription: String {
        description
    }

    public var description: String {
        switch self {
        case .paused:
            return "paused"
        case .waitingToPlayAtSpecifiedRate:
            return "waitingToPlayAtSpecifiedRate"
        case .playing:
            return "playing"
        @unknown default:
            return "default-unknown"
        }
    }
}
