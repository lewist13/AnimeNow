//
//  VideoPlayer.swift
//  Anime Now!
//
//  Created by ErrorErrorError on 12/23/22.
//  

import AVKit
import Combine
import SwiftUI
import Kingfisher
import Foundation
import MediaPlayer
import AVFoundation
import ViewComponents

public struct VideoPlayer {
    @Binding private var gravity: Gravity
    @Binding private var pipActive: Bool

    private let player: AVPlayer
    private var onPictureInPictureStatusChangedCallback: ((PIPStatus) -> Void)? = nil

    public init(
        player: AVPlayer,
        gravity: Binding<Gravity>,
        pipActive: Binding<Bool>
    ) {
        self.player = player
        self._gravity = gravity
        self._pipActive = pipActive
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
        if platformView.videoGravity != gravity {
            platformView.videoGravity = gravity
        }

        guard let pipController = context.coordinator.controller else { return }

        if pipActive && !pipController.isPictureInPictureActive {
            pipController.startPictureInPicture()
        } else if !pipActive && pipController.isPictureInPictureActive {
            pipController.stopPictureInPicture()
        }
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
            self.controller?.delegate = self
        }

        public func pictureInPictureControllerWillStartPictureInPicture(_ pictureInPictureController: AVPictureInPictureController) {
            videoPlayer.onPictureInPictureStatusChangedCallback?(.willStart)
        }

        public func pictureInPictureControllerDidStartPictureInPicture(_ pictureInPictureController: AVPictureInPictureController) {
            videoPlayer.onPictureInPictureStatusChangedCallback?(.didStart)
            videoPlayer.pipActive = true
        }

        public func pictureInPictureControllerWillStopPictureInPicture(_ pictureInPictureController: AVPictureInPictureController) {
            videoPlayer.onPictureInPictureStatusChangedCallback?(.willStop)
        }

        public func pictureInPictureControllerDidStopPictureInPicture(_ pictureInPictureController: AVPictureInPictureController) {
            videoPlayer.onPictureInPictureStatusChangedCallback?(.didStop)
            videoPlayer.pipActive = false
        }

        public func pictureInPictureController(_ pictureInPictureController: AVPictureInPictureController, restoreUserInterfaceForPictureInPictureStopWithCompletionHandler completionHandler: @escaping (Bool) -> Void) {
            videoPlayer.onPictureInPictureStatusChangedCallback?(.restoreUI)
            completionHandler(true)
        }

        public func pictureInPictureController(_ pictureInPictureController: AVPictureInPictureController, failedToStartPictureInPictureWithError error: Error) {
            videoPlayer.onPictureInPictureStatusChangedCallback?(.failedToStart)
            videoPlayer.pipActive = false
        }
    }
}

extension VideoPlayer {
    public func onPictureInPictureStatusChanged(
        _ callback: @escaping (PIPStatus) -> Void
    ) -> Self {
        var view = self
        view.onPictureInPictureStatusChangedCallback = callback
        return view
    }
}

extension VideoPlayer {
    public final class PlayerView: PlatformView {
        var playerLayer: AVPlayerLayer { layer as! AVPlayerLayer }

        var player: AVPlayer? {
            get { playerLayer.player }
            set { playerLayer.player = newValue }
        }

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

        init(player: AVPlayer) {
            super.init(frame: .zero)
            #if os(macOS)
            self.wantsLayer = true
            #endif
            self.player = player
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }
}

extension VideoPlayer.PlayerView {
    func updatePlayer(_ player: AVPlayer) {
        self.player = player
    }
}
