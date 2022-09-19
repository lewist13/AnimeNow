//
//  PlayerView.swift
//  Anime Now!
//
//  Created Erik Bautista on 9/14/22.
//  Copyright © 2022. All rights reserved.
//

import UIKit
import SwiftUI
import Combine
import AVFoundation
import ComposableArchitecture
import AVKit

struct AVPlayerCore {
    enum AVAction: Equatable {
        case initialize
        case play
        case pause
        case stop
        case start(media: AVPlayerItem)
        case seek(to: CMTime)
        case appendMedia(AVPlayerItem)
        case videoGravity(AVLayerVideoGravity)
    }

    struct State: Equatable {
        var avAction: AVAction?

        var status = AVPlayer.Status.unknown
        var timeStatus = AVPlayer.TimeControlStatus.paused
        var rate = Float.zero
        var currentTime = CMTime.zero
        var videoGravity = AVLayerVideoGravity.resizeAspect
        var duration: CMTime?
    }

    enum Action: Equatable {
        case avAction(AVAction?)

        case status(AVPlayer.Status)
        case timeStatus(AVPlayer.TimeControlStatus, AVPlayer.WaitingReason?)
        case rate(Float)
        case currentTime(CMTime)
        case videoGravity(AVLayerVideoGravity)
        case duration(CMTime?)
    }
}

extension AVPlayerCore {
    static let reducer = Reducer<Self.State, Self.Action, Void> { state, action, _ in
        switch action {
        case .status(let status):
            state.status = status
        case .timeStatus(let timeStatus, let waitingReason):
            state.timeStatus = timeStatus
        case .rate(let rate):
            state.rate = rate
        case .currentTime(let currentTime):
            state.currentTime = currentTime
        case .videoGravity(let gravity):
            state.videoGravity = gravity
        case .duration(let duration):
            state.duration = duration
        case .avAction(let action):
            state.avAction = action
        }
        return .none
    }
}

struct AVPlayerView: UIViewRepresentable {
    let store: Store<AVPlayerCore.State, AVPlayerCore.Action>

    func makeUIView(context: Context) -> AVPlayerUIView {
        let view = AVPlayerUIView(
            store: store
        )

        view.avDelegate = context.coordinator
        return view
    }

    func updateUIView(_ uiView: AVPlayerUIView, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(
            self
        )
    }

    class Coordinator: NSObject, AVPictureInPictureControllerDelegate {
        private let parent: AVPlayerView

        init(
            _ parent: AVPlayerView
        ) {
            self.parent = parent
        }

        func pictureInPictureControllerWillStartPictureInPicture(_ pictureInPictureController: AVPictureInPictureController) {
            print("PIP Starting")
        }

        func pictureInPictureControllerWillStopPictureInPicture(_ pictureInPictureController: AVPictureInPictureController) {
            print("PIP Ending")
        }

        func pictureInPictureController(_ pictureInPictureController: AVPictureInPictureController, restoreUserInterfaceForPictureInPictureStopWithCompletionHandler completionHandler: @escaping (Bool) -> Void) {
            print("PIP restore user interface")
            completionHandler(true)
        }

        func pictureInPictureController(_ pictureInPictureController: AVPictureInPictureController, failedToStartPictureInPictureWithError error: Error) {
            print("PIP Error starting PIP")
        }
    }
}

class AVPlayerUIView: UIView {
    private let store: Store<AVPlayerCore.State, AVPlayerCore.Action>
    private let viewStore: ViewStore<AVPlayerCore.State, AVPlayerCore.Action>
    private var cancellables: Set<AnyCancellable> = []

    private let player = AVQueuePlayer()
    private var playerLayer: AVPlayerLayer { layer as! AVPlayerLayer }
    override static var layerClass: AnyClass { AVPlayerLayer.self }

    private var timerObserver: Any? = nil
    private var playerItemCancellables = Set<AnyCancellable>()

    private var controller: AVPictureInPictureController?

    weak var avDelegate: AVPictureInPictureControllerDelegate? {
        set {
            controller?.delegate = newValue
        }
        get {
            controller?.delegate
        }
    }

    init(store: Store<AVPlayerCore.State, AVPlayerCore.Action>) {
        self.store = store
        self.viewStore = ViewStore(store)
        super.init(frame: .zero)
        self.controller = .init(playerLayer: playerLayer)

        bindStore()
        self.playerLayer.player = player
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func bindStore() {
        viewStore.publisher.avAction
            .compactMap { $0 }
            .sink { [weak self] action in
                switch action {
                case .initialize:
                    self?.observePlayer()
                    self?.observePiP()
                case .play:
                    self?.player.playImmediately(atRate: 1.0)
                case .pause:
                    self?.player.pause()
                case .stop:
                    self?.player.pause()
                    self?.player.removeAllItems()
                    self?.cancellables.removeAll()
                    self?.playerItemCancellables.removeAll()
                case .seek(to: let time):
                    self?.player.seek(to: time, toleranceBefore: .zero, toleranceAfter: .zero)
                case .appendMedia(let primaryItem):
                    self?.player.insert(primaryItem, after: nil)
                case .start(media: let media):
                    self?.player.replaceCurrentItem(with: media)
                case .videoGravity(let gravity):
                    self?.playerLayer.videoGravity = gravity
                }
            }
            .store(in: &cancellables)
    }

    private func observePlayer() {
        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .moviePlayback, policy: .longFormVideo)

        playerLayer.publisher(
            for: \.videoGravity
        )
        .sink { [weak self] gravity in
            self?.viewStore.send(.videoGravity(gravity))
        }
        .store(in: &cancellables)
        
        player.publisher(
            for: \.currentItem
        )
        .sink { [weak self] item in
            self?.startListeningToNewPlayerItem(playerItem: item)
        }
        .store(in: &cancellables)

        player.publisher(
            for: \.status
        )
        .sink { [weak self] status in
            self?.viewStore.send(.status(status))
        }
        .store(in: &cancellables)

        player.publisher(
            for: \.rate
        )
            .sink { [weak self] rate in
                self?.viewStore.send(.rate(rate))
            }
            .store(in: &cancellables)

        player.publisher(
            for: \.timeControlStatus
        )
        .zip(
            player.publisher(
                for: \.reasonForWaitingToPlay
            )
        )
            .sink { [weak self] (timeStatus, statusWarning) in
                self?.viewStore.send(.timeStatus(timeStatus, statusWarning))
            }
            .store(in: &cancellables)

        if let timerObserver = timerObserver {
            player.removeTimeObserver(timerObserver)
            self.timerObserver = nil
        }

        timerObserver = player.addPeriodicTimeObserver(
            forInterval: .init(
                seconds: 0.5,
                preferredTimescale: CMTimeScale(NSEC_PER_SEC)
            ),
            queue: .main
        ) { [weak self] time in
            self?.viewStore.send(.currentTime(time))
        }
    }

    private func observePiP() {
//        controller.publisher(for: \.)
    }

    private func startListeningToNewPlayerItem(playerItem: AVPlayerItem?) {
        guard let playerItem = playerItem else {
            playerItemCancellables.removeAll()
            self.viewStore.send(.duration(nil))
            return
        }

        playerItem.publisher(
            for: \.duration
        )
        .filter(\.isNumeric)
        .sink { [weak self] duration in
            self?.viewStore.send(.duration(duration))
        }
        .store(in: &playerItemCancellables)
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
