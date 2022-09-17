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
        case seek(to: CMTime)
        case appendMedia(AVPlayerItem)
        case start(media: AVPlayerItem)
    }

    struct State: Equatable {
        var avAction: AVAction?

        var status = AVPlayer.Status.unknown
        var timeStatus = AVPlayer.TimeControlStatus.paused
        var rate = Float.zero
        var currentTime = CMTime.zero
    }

    enum Action: Equatable {
        case avAction(AVAction?)

        case status(AVPlayer.Status)
        case timeStatus(AVPlayer.TimeControlStatus, AVPlayer.WaitingReason?)
        case rate(Float)
        case currentTime(CMTime)
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
        case .avAction(let action):
            state.avAction = action
        }
        return .none
    }
        .debug()
}

struct AVPlayerView: UIViewRepresentable {
    let store: Store<AVPlayerCore.State, AVPlayerCore.Action>

    func makeUIView(context: Context) -> AVPlayerUIView {
        AVPlayerUIView(
            store: store
        )
    }

    func updateUIView(_ uiView: AVPlayerUIView, context: Context) {}
}

class AVPlayerUIView: UIView {
    private let store: Store<AVPlayerCore.State, AVPlayerCore.Action>
    private let viewStore: ViewStore<AVPlayerCore.State, AVPlayerCore.Action>
    private var cancellables: Set<AnyCancellable> = []

    private let player = AVQueuePlayer()
    private var playerLayer: AVPlayerLayer { layer as! AVPlayerLayer }
    override static var layerClass: AnyClass { AVPlayerLayer.self }

    private var timerObserver: Any? = nil

    init(store: Store<AVPlayerCore.State, AVPlayerCore.Action>) {
        self.store = store
        self.viewStore = ViewStore(store)
        super.init(frame: .zero)

        bindStore()
        self.playerLayer.player = player
        self.isUserInteractionEnabled = false
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func bindStore() {
        viewStore.publisher.avAction
            .sink { [weak self] action in
                guard let action = action else {
                    return
                }
                switch action {
                case .initialize:
                    self?.observePlayer()
                case .play:
                    self?.player.playImmediately(atRate: 1.0)
                case .pause:
                    self?.player.pause()
                case .stop:
                    self?.player.pause()
                    self?.player.removeAllItems()
                case .seek(to: let time):
                    self?.player.seek(to: time)
                case .appendMedia(let primaryItem):
                    self?.player.insert(primaryItem, after: nil)
                case .start(media: let media):
                    self?.player.replaceCurrentItem(with: media)
                }
            }
            .store(in: &cancellables)
    }

    private func observePlayer() {
        DispatchQueue.global().async {
            try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .moviePlayback, policy: .longFormVideo)
        }

        player.publisher(
            for: \.status
        )
            .sink(receiveValue: { [weak self] status in
                self?.viewStore.send(.status(status))
            })
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
                value: 1,
                timescale: 1
            ),
            queue: .main
        ) { [weak self] time in
            self?.viewStore.send(.currentTime(time))
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
            return "default"
        }
    }
}
