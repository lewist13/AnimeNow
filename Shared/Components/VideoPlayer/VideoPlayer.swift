//
//  VideoPlayer.swift
//  Anime Now!
//
//  Created by ErrorErrorError on 9/14/22.
//  Copyright © 2022. All rights reserved.
//
//  Modified version of: https://github.com/wxxsw/GSPlayer/blob/master/GSPlayer/Classes/View/InternamVideoPlayerView.swift

import AVKit
import SwiftUI

public struct VideoPlayer {
    public enum Action: Equatable {
        /// Play  Video
        case play

        /// Pause Video
        case pause

        /// Change Progress
        case seekTo(Double)

        /// Change Volume
        case volume(Double)

        /// Start or stop PiP
        case pictureInPicture(enable: Bool)

        case videoGravity(VideoGravity)

        case destroy
    }

    public enum Status: Equatable {

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

    public enum PIPStatus: Equatable {

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

    public typealias VideoGravity = AVLayerVideoGravity

    /// The URL
    private var url: URL?

    /// Play Binding
    @Binding private var action: Action?

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

    /// Volume Changed Callback
    private var onVolumeChangedCallback: ((Double) -> Void)?

    /// Progress Changed Callback
    private var onProgressChangedCallback: ((Double) -> Void)?

    /// Video Aspect Ratio Changed
    private var onVideoGravityChangedCallback: ((VideoGravity) -> Void)?

    init(url: URL?, action: Binding<Action?>) {
        self.url = url
        self._action = action
    }
}

// MARK: View Representable

extension VideoPlayer: PlatformAgnosticViewRepresentable {
    public func makePlatformView(context: Context) -> PlayerView {
        let view = PlayerView()

        context.coordinator.createPiPController(view: view)
        context.coordinator.startObserver(view: view)

        view.statusDidChange = { status in
            DispatchQueue.main.async { onStatusChangedCallback?(status) }
        }

        view.playedToEndTime = {
            DispatchQueue.main.async { onPlayedToTheEndCallback?() }
        }

        #if os(iOS)
        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .moviePlayback, policy: .longFormVideo)
        #endif

        return view
    }

    public func updatePlatformView(_ view: PlayerView, context: Context) {
        if let url = url {
            if view.play(for: url) {
                // Clear observer
                context.coordinator.clearObservers()
            }
        } else {
            view.stopAndRemoveItem()
            context.coordinator.clearObservers()
            context.coordinator.manualFetch(view: view)
        }

        if let action = action {
            switch action {
            case .play:
                view.resume()
            case .pause:
                view.pause()
            case .seekTo(let progress):
                let time = CMTime(seconds: round(progress * view.totalDuration), preferredTimescale: 1)
                view.seek(to: time)
            case .volume(let volume):
                view.volume(to: volume)
            case .pictureInPicture(enable: true):
                context.coordinator.controller?.startPictureInPicture()
            case .pictureInPicture(enable: false):
                context.coordinator.controller?.stopPictureInPicture()
            case .videoGravity(let videoGravity):
                view.videoGravity = videoGravity
            case .destroy:
                Self.dismantlePlatformView(view, coordinator: context.coordinator)
            }

            DispatchQueue.main.async { self.action = nil }
        }
    }

    public static func dismantlePlatformView(_ view: PlayerView, coordinator: Coordinator) {
        coordinator.removeObservers(view: view)
        view.destroy()
    }

    public func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    public class Coordinator: NSObject {
        var videoPlayer: VideoPlayer
        var observerProgress: Double?
        var observerBuffer: Double?
        var observerDuration: Double?
        var observerVolume: Double?
        var observerGravity: VideoGravity?
        var controller: AVPictureInPictureController?

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
            observerVolume = nil
            observerGravity = nil
        }

        func stopObserver(view: PlayerView) {
            view.periodicTimeChanged = nil
        }

        func manualFetch(view: PlayerView) {
            updateProgress(view: view)
            updateBuffer(view: view)
            updateDuration(view: view)
            updateVolume(view: view)
            updateGravity(view: view)
        }

        func startObserver(view: PlayerView) {
            guard view.periodicTimeChanged == nil else { return }

            view.periodicTimeChanged = { [unowned self] _ in
                self.manualFetch(view: view)
            }
        }

        func updateProgress(view: PlayerView) {
            guard let handler = videoPlayer.onProgressChangedCallback else { return }

            let progress = max(0, min(1.0, view.playProgress))

            guard progress != observerProgress else { return }

            DispatchQueue.main.async { handler(progress) }

            observerProgress = progress
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

            DispatchQueue.main.async { handler(duration) }

            observerDuration = duration
        }

        func updateVolume(view: PlayerView) {
            guard let handler = videoPlayer.onVolumeChangedCallback else { return }

            let volume = view.volume

            guard volume != observerVolume else { return }

            DispatchQueue.main.async { handler(volume) }

            observerVolume = volume
        }

        func updateGravity(view: PlayerView) {
            guard let handler = videoPlayer.onVideoGravityChangedCallback else { return }

            let gravity = view.videoGravity

            guard gravity != observerGravity else { return }

            DispatchQueue.main.async { handler(gravity) }

            observerGravity = gravity
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

    func onVolumeChanged(_ handler: @escaping (Double) -> Void) -> Self {
        var view = self
        view.onVolumeChangedCallback = handler
        return view
    }

    func onProgressChanged(_ handler: @escaping (Double) -> Void) -> Self {
        var view = self
        view.onProgressChangedCallback = handler
        return view
    }

    func onVideoGravityChanged(_ handler: @escaping (VideoGravity) -> Void) -> Self {
        var view = self
        view.onVideoGravityChangedCallback = handler
        return view
    }
}

extension VideoPlayer.Coordinator: AVPictureInPictureControllerDelegate {
    public func pictureInPictureControllerDidStopPictureInPicture(_ pictureInPictureController: AVPictureInPictureController) {
        DispatchQueue.main.async { [weak self] in self?.videoPlayer.onPictureInPictureStatusChangedCallback?(.didStop) }
    }

    public func pictureInPictureControllerDidStartPictureInPicture(_ pictureInPictureController: AVPictureInPictureController) {
        DispatchQueue.main.async { [weak self] in self?.videoPlayer.onPictureInPictureStatusChangedCallback?(.didStart) }
    }

    public func pictureInPictureControllerWillStopPictureInPicture(_ pictureInPictureController: AVPictureInPictureController) {
        DispatchQueue.main.async { [weak self] in self?.videoPlayer.onPictureInPictureStatusChangedCallback?(.willStop) }
    }

    public func pictureInPictureControllerWillStartPictureInPicture(_ pictureInPictureController: AVPictureInPictureController) {
        DispatchQueue.main.async { [weak self] in self?.videoPlayer.onPictureInPictureStatusChangedCallback?(.willStart) }
    }

    public func pictureInPictureController(_ pictureInPictureController: AVPictureInPictureController, failedToStartPictureInPictureWithError error: Error) {
        DispatchQueue.main.async { [weak self] in self?.videoPlayer.onPictureInPictureStatusChangedCallback?(.failedToStart) }
    }

    public func pictureInPictureController(_ pictureInPictureController: AVPictureInPictureController, restoreUserInterfaceForPictureInPictureStopWithCompletionHandler completionHandler: @escaping (Bool) -> Void) {
        DispatchQueue.main.async { [weak self] in
            self?.videoPlayer.onPictureInPictureStatusChangedCallback?(.restoreUI)
            completionHandler(true)
        }
    }
}

struct VideoPlayer_Previews: PreviewProvider {
    @State static var action: VideoPlayer.Action?

    static var previews: some View {
        VideoPlayer(
            url: URL(string: "https://test-streams.mux.dev/x36xhzz/x36xhzz.m3u8")!,
            action: $action
        )
        .onStatusChanged {
            print("Status: \($0)")
        }
        .onDurationChanged {
            print("Duration: \($0)")
        }
        .onProgressChanged {
            print("Progress: \($0)")
        }
        .onPlayedToTheEnd {
            print("Finished playing video")
        }
        .onBufferChanged {
            print("Buffer: \($0)")
        }
        .onPictureInPictureStatusChanged {
            print("Picture in Picture: \($0)")
        }
        .preferredColorScheme(.dark)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

