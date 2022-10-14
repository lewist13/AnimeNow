//
//  VideoPlayer.swift
//  Anime Now!
//
//  Created Erik Bautista on 9/14/22.
//  Copyright © 2022. All rights reserved.
//
//  Modified version of: https://github.com/wxxsw/GSPlayer/blob/master/GSPlayer/Classes/View/InternamVideoPlayerView.swift

import AVKit
import SwiftUI
import Combine
import AVFoundation

struct VideoPlayer {
    enum Action: Equatable {
        case play
        case pause
    }

    enum Status: Equatable {

        /// Idle
        case idle

        /// From the first load to get the first frame of the video
        case loading

        /// Waiting for the next couple of frames to load
        case buffering

        /// Player can start playing
        case readyToPlay

        /// Playing now
        case playing

        /// Video paused
        case paused

        /// An error occurred and cannot continue playing
        case error
    }

    enum PIPStatus: Equatable {

        /// PIP about to start
        case willStart

        /// PIP did start
        case didStart

        /// PIP about to stop
        case willStop

        /// PIP did stop
        case didStop

        /// PIP restore UI before PIP
        case restoreUI

        /// Issue starting PIP
        case failedToStart
    }

    /// The URL
    private var url: URL?

    /// Play Binding
    @Binding private var action: Action?

    /// Progress Binding - ranges from 0...1
    @Binding private var progress: Double

    /// Status Changed Callback
    private var onStatusChangedCallback: ((Status) -> Void)?

    /// Status Changed Callback
    private var onPictureInPictureStatusChangedCallback: ((PIPStatus) -> Void)?

    /// Played to End Callback
    private var onPlayedToTheEndCallback: (() -> Void)?

    /// Buffer Changed Callback
    private var onBufferChangedCallback: ((Double) -> Void)?

    /// Duration Changed Callback
    private var onDurationChangedCallback: ((Double) -> Void)?

    private var onSubtitlesChangedCallback: ((AVMediaSelectionGroup?) -> Void)?

    private var onSubtitleSelectionChangedCallback: ((AVMediaSelectionOption?) -> Void)?

    init(url: URL?, action: Binding<Action?>, progress: Binding<Double> = .constant(.zero)) {
        self.url = url
        self._action = action
        self._progress = progress
    }
}

// MARK: View Representable

extension VideoPlayer: PlatformAgnosticViewRepresentable {
    func makePlatformView(context: Context) -> PlayerView {
        let view = PlayerView()

        view.statusDidChange = { status in
            DispatchQueue.main.async { onStatusChangedCallback?(status) }
        }

        view.playedToEndTime = {
            DispatchQueue.main.async { onPlayedToTheEndCallback?() }
        }

        #if os(iOS)
        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .moviePlayback, policy: .longFormVideo)
        #endif

        context.coordinator.createPiPController(view: view)
        context.coordinator.startObserver(view: view)

        return view
    }

    func updatePlatformView(_ view: PlayerView, context: Context) {
        if let url = url {
            if view.play(for: url) {
                // Clear observer
                context.coordinator.clearObservers()
            }
        } else {
            view.stopAndRemoveItem()
            context.coordinator.clearObservers()
        }

        if let action = action {
            if action == .play {
                view.resume()
            } else if action == .pause {
                view.pause()
            }

            DispatchQueue.main.async { self.action = nil }
        }

        if let observerProgress = context.coordinator.observerProgress, progress != observerProgress {
            let time = CMTime(seconds: round(progress * view.totalDuration), preferredTimescale: 1)
            view.seek(to: time)
        }
    }

    static func dismantlePlatformView(_ view: PlayerView, coordinator: Coordinator) {
        coordinator.removeObservers(view: view)
        view.destroy()
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject {
        var videoPlayer: VideoPlayer
        var observerProgress: Double?
        var observerBuffer: Double?
        var observerDuration: Double?
        var observerSubtitles: AVMediaSelectionGroup?
        var observerSubtitle: AVMediaSelectionOption?
        var controller: AVPictureInPictureController?

        private var cancellables = Set<AnyCancellable>()

        init(_ videoPlayer: VideoPlayer) {
            self.videoPlayer = videoPlayer
        }

        func createPiPController(view: PlayerView) {
            guard controller == nil else { return }
            controller = .init(playerLayer: view.playerLayer)
            controller?.delegate = self
        }

        func removeObservers(view: PlayerView) {
            stopObserver(view: view)
            clearObservers()
        }

        func clearObservers() {
            observerProgress = nil
            observerBuffer = nil
            observerDuration = nil
            observerSubtitles = nil
            observerSubtitle = nil
        }

        func startObserver(view: PlayerView) {
            guard view.periodicTimeChanged == nil else { return }

            view.periodicTimeChanged = { [unowned self] _ in
                let progress = max(0, min(1.0, view.playProgress))

                self.videoPlayer.progress = progress
                self.observerProgress = progress

                self.updateBuffer(view: view)
                self.updateDuration(view: view)
                self.updateSubtitles(view: view)
                self.updateSubtitleSelected(view: view)
            }
        }

        func updateSubtitles(view: PlayerView) {
            guard let handler = videoPlayer.onSubtitlesChangedCallback else { return }

            let legibleGroup = view.player.currentItem?.asset.mediaSelectionGroup(forMediaCharacteristic: .legible)
            guard legibleGroup != observerSubtitles else { return }

            DispatchQueue.main.async { handler(legibleGroup) }

            observerSubtitles = legibleGroup
        }

        func updateSubtitleSelected(view: PlayerView) {
            guard let handler = videoPlayer.onSubtitleSelectionChangedCallback else { return }

            let selectedItem: AVMediaSelectionOption?

            if let legibleGroup = view.player.currentItem?.asset.mediaSelectionGroup(forMediaCharacteristic: .legible) {
                selectedItem = view.player.currentItem?.currentMediaSelection.selectedMediaOption(in: legibleGroup)
            } else {
                selectedItem = nil
            }

            guard selectedItem != observerSubtitle else { return }

            DispatchQueue.main.async { handler(selectedItem) }

            observerSubtitle = selectedItem
        }

        func stopObserver(view: PlayerView) {
            view.periodicTimeChanged = nil
        }

        func updateBuffer(view: PlayerView) {
            guard let handler = videoPlayer.onBufferChangedCallback else { return }

            let bufferProgress = max(0, min(1.0, view.bufferProgress))

            guard bufferProgress != observerBuffer else { return }

            DispatchQueue.main.async { handler(bufferProgress) }

            observerBuffer = bufferProgress
        }

        func updateDuration(view: PlayerView) {
            guard let handler = videoPlayer.onDurationChangedCallback else { return }

            let duration = view.totalDuration

            guard duration != observerDuration else { return }

            observerDuration = duration

            DispatchQueue.main.async { handler(duration) }
        }
    }
}

extension VideoPlayer {
    func onStatusChanged(_ handler: @escaping (Status) -> Void) -> Self {
        var view = self
        view.onStatusChangedCallback = handler
        return view
    }

    func onPictureInPictureStatusChanged(_ handler: @escaping (PIPStatus) -> Void) -> Self {
        var view = self
        view.onPictureInPictureStatusChangedCallback = handler
        return view
    }

    func onPlayedToTheEnd(_ handler: @escaping () -> Void) -> Self {
        var view = self
        view.onPlayedToTheEndCallback = handler
        return view
    }

    func onBufferChanged(_ handler: @escaping (Double) -> Void) -> Self {
        var view = self
        view.onBufferChangedCallback = handler
        return view
    }

    func onDurationChanged(_ handler: @escaping (Double) -> Void) -> Self {
        var view = self
        view.onDurationChangedCallback = handler
        return view
    }

    func onSubtitlesChanged(_ handler: @escaping (AVMediaSelectionGroup?) -> Void) -> Self {
        var view = self
        view.onSubtitlesChangedCallback = handler
        return view
    }

    func onSubtitleSelectionChanged(_ handler: @escaping (AVMediaSelectionOption?) -> Void) -> Self {
        var view = self
        view.onSubtitleSelectionChangedCallback = handler
        return view
    }
}

extension VideoPlayer.Coordinator: AVPictureInPictureControllerDelegate {
    func pictureInPictureControllerDidStopPictureInPicture(_ pictureInPictureController: AVPictureInPictureController) {
        DispatchQueue.main.async { [weak self] in self?.videoPlayer.onPictureInPictureStatusChangedCallback?(.didStop) }
    }

    func pictureInPictureControllerDidStartPictureInPicture(_ pictureInPictureController: AVPictureInPictureController) {
        DispatchQueue.main.async { [weak self] in self?.videoPlayer.onPictureInPictureStatusChangedCallback?(.didStart) }
    }

    func pictureInPictureControllerWillStopPictureInPicture(_ pictureInPictureController: AVPictureInPictureController) {
        DispatchQueue.main.async { [weak self] in self?.videoPlayer.onPictureInPictureStatusChangedCallback?(.willStop) }
    }

    func pictureInPictureControllerWillStartPictureInPicture(_ pictureInPictureController: AVPictureInPictureController) {
        DispatchQueue.main.async { [weak self] in self?.videoPlayer.onPictureInPictureStatusChangedCallback?(.willStart) }
    }

    func pictureInPictureController(_ pictureInPictureController: AVPictureInPictureController, failedToStartPictureInPictureWithError error: Error) {
        DispatchQueue.main.async { [weak self] in self?.videoPlayer.onPictureInPictureStatusChangedCallback?(.failedToStart) }
    }

    func pictureInPictureController(_ pictureInPictureController: AVPictureInPictureController, restoreUserInterfaceForPictureInPictureStopWithCompletionHandler completionHandler: @escaping (Bool) -> Void) {
        DispatchQueue.main.async { [weak self] in
            self?.videoPlayer.onPictureInPictureStatusChangedCallback?(.restoreUI)
            completionHandler(true)
        }
    }
}
