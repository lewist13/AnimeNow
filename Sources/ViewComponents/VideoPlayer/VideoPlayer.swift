//
//  VideoPlayer.swift
//  Anime Now!
//
//  Created by ErrorErrorError on 12/23/22.
//  

import AVKit
import Combine
import Kingfisher
import Foundation
import MediaPlayer
import AVFoundation

public struct VideoPlayer {
    private let player: AVPlayer

    private var onPictureInPictureStatusChangedCallback: ((PIPStatus) -> Void)? = nil
    private var onVideoGravityChangedCallback: ((Gravity) -> Void)? = nil

    public init(player: AVPlayer) {
        self.player = player
    }
}

public extension VideoPlayer {
    enum PIPStatus: Equatable {
        case willStart
        case didStart
        case willStop
        case didStop
        case restoreUI
        case failedToStart
    }

    typealias Gravity = AVLayerVideoGravity
}

extension VideoPlayer {
    public func onPictureInPictureStatusChanged(
        _ callback: @escaping (PIPStatus) -> Void
    ) -> Self {
        var view = self
        view.onPictureInPictureStatusChangedCallback = callback
        return view
    }

    public func onVideoGravityChanged(
        _ callback: @escaping (Gravity) -> Void
    ) -> Self {
        var view = self
        view.onVideoGravityChangedCallback = callback
        return view
    }
}

extension VideoPlayer: PlatformAgnosticViewRepresentable {
    public func makeCoordinator() -> Coordinator {
        .init(self)
    }

    public func makePlatformView(
        context: Context
    ) -> PlayerView {
        let view = PlayerView(player: player)
        context.coordinator.addDelegate(view)
        return view
    }

    public func updatePlatformView(
        _ platformView: PlayerView,
        context: Context
    ) {
        platformView.updatePlayer(player)
    }
}

extension VideoPlayer {
    public final class Coordinator: NSObject, AVPictureInPictureControllerDelegate {
        let videoPlayer: VideoPlayer
        var controller: AVPictureInPictureController? = nil

        init(_ videoPlayer: VideoPlayer) {
            self.videoPlayer = videoPlayer
            super.init()
        }

        func addDelegate(_ view: PlayerView) {
            guard controller == nil else { return }
            self.controller = .init(playerLayer: view.playerLayer)
        }

        public func pictureInPictureControllerWillStartPictureInPicture(_ pictureInPictureController: AVPictureInPictureController) {
            videoPlayer.onPictureInPictureStatusChangedCallback?(.willStart)
        }

        public func pictureInPictureControllerDidStartPictureInPicture(_ pictureInPictureController: AVPictureInPictureController) {
            videoPlayer.onPictureInPictureStatusChangedCallback?(.didStart)
        }

        public func pictureInPictureControllerWillStopPictureInPicture(_ pictureInPictureController: AVPictureInPictureController) {
            videoPlayer.onPictureInPictureStatusChangedCallback?(.willStop)
        }

        public func pictureInPictureControllerDidStopPictureInPicture(_ pictureInPictureController: AVPictureInPictureController) {
            videoPlayer.onPictureInPictureStatusChangedCallback?(.didStop)
        }

        public func pictureInPictureController(_ pictureInPictureController: AVPictureInPictureController, restoreUserInterfaceForPictureInPictureStopWithCompletionHandler completionHandler: @escaping (Bool) -> Void) {
            videoPlayer.onPictureInPictureStatusChangedCallback?(.restoreUI)
            completionHandler(true)
        }

        public func pictureInPictureController(_ pictureInPictureController: AVPictureInPictureController, failedToStartPictureInPictureWithError error: Error) {
            videoPlayer.onPictureInPictureStatusChangedCallback?(.failedToStart)
        }
    }
}

extension VideoPlayer {
    public final class PlayerView: PlatformView {
        var player: AVPlayer
        var playerLayer: AVPlayerLayer { layer as! AVPlayerLayer }

        #if os(iOS)
        public override class var layerClass: AnyClass { AVPlayerLayer.self }
        #else
        public override func makeBackingLayer() -> CALayer { AVPlayerLayer() }
        #endif

        var videoGravity: AVLayerVideoGravity {
            get {
                playerLayer.videoGravity
            }
            set {
                playerLayer.videoGravity = newValue
            }
        }

        init(
            player: AVPlayer
        ) {
            self.player = player
            super.init(frame: .zero)
            configureInit()
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }
}

extension VideoPlayer.PlayerView {
    private func configureInit() {
        #if os(macOS)
        self.wantsLayer = true
        #endif

        updatePlayer(self.player)

        #if os(iOS)
        try? AVAudioSession.sharedInstance().setCategory(
            .playback,
            mode: .moviePlayback,
            policy: .longFormVideo
        )
        #endif
    }

    func updatePlayer(
        _ player: AVPlayer
    ) {
        self.player = player
        self.playerLayer.player = player
    }
}

extension VideoPlayer.PlayerView {
    func resize(_ gravity: AVLayerVideoGravity) {
        self.videoGravity = gravity
    }

    func pictureInPicture(_ enabled: Bool) {
        
    }
}
