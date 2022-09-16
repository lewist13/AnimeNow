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

struct AVPlayerCore {
    enum AVAction: Equatable {
        case begin
        case play
        case pause
        case stop
        case seek(to: CMTime)
        case setPrimaryItem(AVPlayerItem)
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
        case timeStatus(AVPlayer.TimeControlStatus)
        case rate(Float)
        case currentTime(CMTime)
    }
}

extension AVPlayerCore {
    static let reducer = Reducer<Self.State, Self.Action, Void> { state, action, _ in
        switch action {
        case .status(let status):
            state.status = status
        case .timeStatus(let timeStamp):
            state.timeStatus = timeStamp
        case .rate(let rate):
            state.rate = rate
        case .currentTime(let currentTime):
            state.currentTime = currentTime
        case .avAction(let action):
            state.avAction = action
        }
        return .none
    }
        .debugActions()
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
    override static var layerClass: AnyClass { AVPlayerLayer.self }

    private let store: Store<AVPlayerCore.State, AVPlayerCore.Action>
    private let viewStore: ViewStore<AVPlayerCore.State, AVPlayerCore.Action>
    private var cancellables: Set<AnyCancellable> = []

    private var playerLayer: AVPlayerLayer { layer as! AVPlayerLayer }
    private var player = AVQueuePlayer()

    private var timerObserver: Any? = nil

    init(store: Store<AVPlayerCore.State, AVPlayerCore.Action>) {
        self.store = store
        self.viewStore = ViewStore(store)
        super.init(frame: .zero)
        bindStore()
        playerLayer.player = player
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
                case .begin:
                    self?.observePlayerValues()
                case .play:
                    self?.player.play()
                case .pause:
                    self?.player.pause()
                case .stop:
                    self?.player.pause()
                    self?.player.replaceCurrentItem(with: nil)
                case .seek(to: let time):
                    self?.player.seek(to: time)
                case .setPrimaryItem(let primaryItem):
                    self?.player.replaceCurrentItem(with: primaryItem)
                case .start(media: let media):
                    self?.player.removeAllItems()
                    self?.player.insert(media, after: nil)
                    let session = AVAudioSession.sharedInstance()
                    try? session.setCategory(.playback, mode: .moviePlayback, policy: .longFormVideo)
                    self?.player.play()
                }
            }
            .store(in: &cancellables)
    }

    private func observePlayerValues() {
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
            .sink { [weak self] timeControlStatus in
                self?.viewStore.send(.timeStatus(timeControlStatus))
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
