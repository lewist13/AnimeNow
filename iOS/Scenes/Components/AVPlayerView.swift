//
//  PlayerView.swift
//  Anime Now!
//
//  Created Erik Bautista on 9/14/22.
//  Copyright © 2022. All rights reserved.
//

import AVKit
import UIKit
import SwiftUI
import Combine
import AVFoundation
import ComposableArchitecture

struct AVPlayerCore {
    enum PIPStatus: Equatable {
        case willStart
        case didStart
        case willStop
        case didStop
        case restoreUI
    }

    enum AVAction: Equatable {
        case initialize
        case play
        case pause
        case stop
        case replay
        case terminate
        case start(media: AVPlayerItem)
        case seek(to: CMTime)
        case appendMedia(AVPlayerItem)
        case videoGravity(AVLayerVideoGravity)
    }

    struct State: Equatable {
        var action = [AVAction]()

        var status = AVPlayer.Status.unknown
        var playerItemStatus = AVPlayerItem.Status.unknown
        var timeStatus = AVPlayer.TimeControlStatus.paused
        var currentTime = CMTime.zero
        var videoGravity = AVLayerVideoGravity.resizeAspect
        var duration: CMTime?
        var pipStatus: PIPStatus = .restoreUI
    }

    enum Action: Equatable {
        case pushAction(AVAction)
        case dequeueAction

        case status(AVPlayer.Status)
        case playerItemStatus(AVPlayerItem.Status)
        case timeStatus(AVPlayer.TimeControlStatus, AVPlayer.WaitingReason?)
        case currentTime(CMTime)
        case videoGravity(AVLayerVideoGravity)
        case duration(CMTime?)
        case pipStatus(PIPStatus)
    }
}

extension AVPlayerCore {
    static let reducer = Reducer<Self.State, Self.Action, Void> { state, action, _ in
        switch action {
        case .status(let status):
            state.status = status
        case .timeStatus(let timeStatus, let waitingReason):
            state.timeStatus = timeStatus
        case .currentTime(let currentTime):
            state.currentTime = currentTime
        case .videoGravity(let gravity):
            state.videoGravity = gravity
        case .duration(let duration):
            state.duration = duration
        case .pushAction(let action):
            state.action.append(action)
        case .dequeueAction:
            if !state.action.isEmpty {
               _ = state.action.removeFirst()
            }

        case .playerItemStatus(let status):
            state.playerItemStatus = status
        case .pipStatus(let status):
            state.pipStatus = status
        }
        return .none
    }
}

struct AVPlayerView: UIViewControllerRepresentable {
    let store: Store<AVPlayerCore.State, AVPlayerCore.Action>

    func makeUIViewController(context: Context) -> PlayerViewController {
        PlayerViewController(
            store: store
        )
    }

    func updateUIViewController(_ uiView: PlayerViewController, context: Context) {}
}

class PlayerViewController: UIViewController {
    private let store: Store<AVPlayerCore.State, AVPlayerCore.Action>
    private let viewStore: ViewStore<AVPlayerCore.State, AVPlayerCore.Action>
    private var cancellables: Set<AnyCancellable> = []

    private let player = AVQueuePlayer()
    private lazy var playerLayer = AVPlayerLayer(player: player)

    private var timerObserver: Any? = nil
    private var playerItemCancellables = Set<AnyCancellable>()

    private lazy var controller: AVPictureInPictureController? = .init(playerLayer: playerLayer)

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        .landscape
    }

    override var shouldAutorotate: Bool {
        true
    }

    override var prefersHomeIndicatorAutoHidden: Bool {
        true
    }

    init(store: Store<AVPlayerCore.State, AVPlayerCore.Action>) {
        self.store = store
        self.viewStore = .init(store)
        super.init(nibName: nil, bundle: nil)

        view.layer.insertSublayer(playerLayer, at: 0)
        player.automaticallyWaitsToMinimizeStalling = true
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        bindStore()
    }

    private func bindStore() {
        controller?.delegate = self

        viewStore.publisher.action
            .compactMap { $0.first }
            .print()
            .sink { [weak self] action in
                switch action {
                case .initialize:
                    break
                case .play:
                    self?.player.playImmediately(atRate: 1.0)
                case .pause:
                    self?.player.pause()
                case .replay:
                    self?.player.seek(to: .zero)
                case .stop:
                    self?.player.pause()
                    self?.player.removeAllItems()
                    self?.playerItemCancellables.removeAll()
                case .terminate:
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

                self?.viewStore.send(.dequeueAction)
            }
            .store(in: &cancellables)

        observePlayer()
        observePiP()
    }

    private func handleAVAction(_ action: AVPlayerCore.AVAction?) {
        
    }

    private func observePlayer() {
        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .moviePlayback, policy: .longFormVideo)
        player.allowsExternalPlayback = true

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
            self?.observePlayerItem(item)
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

    private func observePlayerItem(_ playerItem: AVPlayerItem?) {
        guard let playerItem = playerItem else {
            playerItemCancellables.removeAll()
            self.viewStore.send(.duration(nil))
            self.viewStore.send(.playerItemStatus(.unknown))
            return
        }

        playerItem.publisher(
            for: \.duration
        )
        .filter(\.isNumeric)
        .removeDuplicates()
        .sink { [weak self] duration in
            self?.viewStore.send(.duration(duration))
        }
        .store(in: &playerItemCancellables)

        playerItem.publisher(
            for: \.status
        )
        .removeDuplicates()
        .sink { [weak self] status in
            self?.viewStore.send(.playerItemStatus(status))
        }
        .store(in: &playerItemCancellables)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        playerLayer.frame = view.frame
    }
}

extension PlayerViewController: AVPictureInPictureControllerDelegate {
    public func pictureInPictureControllerWillStartPictureInPicture(_: AVPictureInPictureController) {
        viewStore.send(.pipStatus(.willStart))
    }

    public func pictureInPictureControllerDidStartPictureInPicture(_: AVPictureInPictureController) {
        viewStore.send(.pipStatus(.didStart))
    }

    public func pictureInPictureControllerWillStopPictureInPicture(_: AVPictureInPictureController) {
        viewStore.send(.pipStatus(.willStop))
    }

    public func pictureInPictureControllerDidStopPictureInPicture(_: AVPictureInPictureController) {
        viewStore.send(.pipStatus(.didStop))
    }

    public func pictureInPictureController(_: AVPictureInPictureController, restoreUserInterfaceForPictureInPictureStopWithCompletionHandler completionHandler: @escaping (Bool) -> Void) {
        viewStore.send(.pipStatus(.restoreUI))
        completionHandler(true)
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
