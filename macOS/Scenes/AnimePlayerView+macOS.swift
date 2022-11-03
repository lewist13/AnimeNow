//
//  AnimePlayerView+macOS.swift
//  Anime Now! (macOS)
//
//  Created by ErrorErrorError on 10/16/22.
//

import SwiftUI
import AppKit
import ComposableArchitecture

extension AnimePlayerView {
    @ViewBuilder
    var playerControlsOverlay: some View {
        WithViewStore(
            store,
            observe: { $0.canShowPlayerOverlay }
        ) { viewState in
            GeometryReader { proxy in
                VStack(spacing: 0) {
                    if viewState.state {
                        topPlayerItems
                    }
                    Spacer()
                    skipButton
                    if viewState.state {
                        bottomPlayerItems
                    }
                }
                .frame(
                    maxWidth: .infinity,
                    maxHeight: .infinity
                )
                .padding(24)
                .background(
                    Color.black.opacity(0.5)
                        .ignoresSafeArea()
                        .allowsHitTesting(false)
                        .opacity(viewState.state ? 1 : 0)
                )
            }
        }
        .overlay(statusOverlay)
        .mouseEvents(
            options: [.activeAlways, .mouseEnteredAndExited, .mouseMoved]
        ) { event in
            let viewState = ViewStore(store.stateless)

            if event == .mouseMoved {
                viewState.send(.onMouseMoved)
            } else {
                viewState.send(.isHoveringPlayer(event == .mouseEntered))
            }
        }
        .onReceive(
            ViewStore(store).publisher.canShowPlayerOverlay
        ) { showOverlay in
            showOverlay ? NSCursor.unhide() : NSCursor.setHiddenUntilMouseMoves(true)
        }
        .onKeyDown { key in
            let viewStore = ViewStore(store)
            switch key {
            case .spaceBar:
                viewStore.send(.togglePlayback)
            case .leftArrow:
                viewStore.send(.backwardsTapped)
            case .rightArrow:
                viewStore.send(.forwardsTapped)
            case .downArrow:
                viewStore.send(.volume(to: viewStore.playerVolume - 0.10))
            case .upArrow:
                viewStore.send(.volume(to: viewStore.playerVolume + 0.10))
            }
        }
        .onReceive(ViewStore(store).publisher.playerIsFullScreen) { isFullScreen in
            NSWindow.ButtonType.allCases
                .forEach {
                    NSApp.mainWindow?
                        .standardWindowButton($0)?
                        .isHidden = !isFullScreen
                }
        }
        .onAppear {
            NSWindow.ButtonType.allCases
                .forEach {
                    NSApp.mainWindow?
                        .standardWindowButton($0)?
                        .isHidden = true
                }
        }
        .onDisappear {
            NSWindow.ButtonType.allCases
                .forEach {
                    NSApp.mainWindow?
                        .standardWindowButton($0)?
                        .isHidden = false
                }
            NSCursor.unhide()
        }
    }
}

// MARK: Status Overlay

extension AnimePlayerView {
    @ViewBuilder
    var statusOverlay: some View {
        WithViewStore(
            store,
            observe: { $0.status }
        ) { viewState in
            if viewState.state == .loading {
                loadingView
            } else if viewState.state == .paused || viewState.state == .replay {
                Image(systemName: viewState.state == .paused ? "play.fill" : "arrow.counterclockwise")
                    .font(.title.bold())
                    .contentShape(Rectangle())
                    .onTapGesture {
                        viewState.send(viewState.state == .paused ? .togglePlayback : .replayTapped)
                    }
                    .foregroundColor(Color.white)
            }
        }
    }
}

// MARK: Top Player Items

extension AnimePlayerView {
    @ViewBuilder
    var topPlayerItems: some View {
        HStack(alignment: .center) {
            dismissButton
            animeInfoView
            Spacer()
            pipButton
            airplayButton
        }
        .frame(maxWidth: .infinity)
        .transition(.opacity)
    }

    @ViewBuilder
    var pipButton: some View {
        WithViewStore(
            store,
            observe: { $0.playerPiPStatus == .didStart }
        ) { viewStore in
            Image(
                systemName: viewStore.state ? "rectangle.center.inset.filled" : "rectangle.inset.bottomright.filled"
            )
            .font(.title2.bold())
            .contentShape(Rectangle())
            .onTapGesture {
                viewStore.send(.togglePictureInPicture)
            }
            .foregroundColor(Color.white)
        }
    }
}

// MARK: Bottom Player Items

extension AnimePlayerView {
    @ViewBuilder
    var bottomPlayerItems: some View {
        VStack {
            progressView
            HStack(spacing: 20) {
                playStateView
                volumeButton
                nextEpisodeButton
                durationView
                Spacer()
                subtitlesButton
                    .popoverStore(
                        store: store.scope(
                            state: { $0.showSubtitlesOverlay }
                        ),
                        onDismiss: { ViewStore(store).send(.closeSidebar) }
                    ) { _ in
                        sidebarOverlay
                            .frame(
                                height: 300
                            )
                    }
                episodesButton
                settingsButton
                    .popoverStore(
                        store: store.scope(
                            state: { $0.showSettingsOverlay }
                        ),
                        onDismiss: { ViewStore(store).send(.closeSidebar) }
                    ) { _ in
                        sidebarOverlay
                            .frame(
                                height: 300
                            )
                    }
                fullscreenButton
            }
        }
    }

    @ViewBuilder
    var playStateView: some View {
        WithViewStore(
            store,
            observe: { $0.playerStatus == .playing }
        ) { viewState in
            Image(systemName: viewState.state ? "pause.fill" : "play.fill")
                .font(.title2.bold())
                .contentShape(Rectangle())
                .onTapGesture {
                    viewState.send(.togglePlayback)
                }
                .foregroundColor(Color.white)
        }
    }

    @ViewBuilder
    var progressView: some View {
        WithViewStore(
            store,
            observe: ProgressViewState.init
        ) { viewState in
            SeekbarView(
                progress: .init(
                    get: { viewState.progress },
                    set: { viewState.send(.seeking(to: $0)) }
                ),
                buffered: viewState.state.buffered,
                padding: 6
            ) {
                viewState.send($0 ? .startSeeking : .stopSeeking)
            }
            .frame(height: 20)
            .disabled(!viewState.isLoaded)
        }
    }

    @ViewBuilder
    var durationView: some View {
        WithViewStore(
            store,
            observe: ProgressViewState.init
        ) { viewState in
            HStack(spacing: 4) {
                Text(
                    viewState.progressWithDuration?.timeFormatted ?? "--:--"
                )
                Text("/")
                Text(
                    viewState.isLoaded ? viewState.duration.timeFormatted : "--:--"
                )
            }
            .foregroundColor(.white)
            .font(.body.bold().monospacedDigit())
        }
    }

    private enum VolumeViewState: Equatable {
        case muted
        case low
        case mid
        case high

        init(_ state: AnimePlayerReducer.State) {
            if state.playerProgress > 2/3 {
                self = .high
            } else if state.playerVolume > 1/3 {
                self = .mid
            } else if state.playerVolume > 0 {
                self = .low
            } else {
                self = .muted
            }
        }

        var image: String {
            switch self {
//            case .muted:
//                return "speaker.slash.fill"
//            case .low:
//                return "speaker.wave.1.fill"
//            case .mid:
//                return "speaker.wave.2.fill"
//            case .high:
            default:
                return "speaker.wave.3.fill"
            }
        }
    }

    @ViewBuilder
    var volumeButton: some View {
        HStack {
            WithViewStore(
                store,
                observe: VolumeViewState.init
            ) { viewState in
                // TODO: Fix since this bugs the volume slider
                Image(
                    systemName: viewState.image
                )
                .font(.title2.bold())
                .contentShape(Rectangle())
                .foregroundColor(Color.white)
            }

            WithViewStore(
                store,
                observe: { $0.playerVolume }
            ) { viewState in
                SeekbarView(
                    progress: .init(
                        get: { viewState.state },
                        set: { viewState.send(.volume(to: $0)) }
                    ),
                    padding: 0
                )
                .frame(
                    width: 75,
                    height: 6
                )
            }
        }
    }

    @ViewBuilder
    var fullscreenButton: some View {
        WithViewStore(
            store,
            observe: { $0.playerIsFullScreen }
        ) { viewState in
            Image(systemName: viewState.state ? "arrow.down.right.and.arrow.up.left" : "arrow.up.backward.and.arrow.down.forward")
                .font(.title2.bold())
                .foregroundColor(Color.white)
                .contentShape(Rectangle())
                .onTapGesture {
                    NSApp.mainWindow?.toggleFullScreen(nil)
                }
        }
    }
}

struct VideoPlayerViewMacOS_Previews: PreviewProvider {
    static var previews: some View {
        AnimePlayerView(
            store: .init(
                initialState: .init(
                    anime: .init(Anime.narutoShippuden),
                    episodes: .init(Episode.demoEpisodes.map({ $0.asRepresentable() })),
                    selectedEpisode: Episode.demoEpisodes.first!.id
                ),
                reducer: AnimePlayerReducer()
            )
        )
    }
}

extension NSWindow.ButtonType: CaseIterable {
    public static var allCases: [NSWindow.ButtonType] {
        [.closeButton, .zoomButton, .miniaturizeButton, .documentIconButton, .documentVersionsButton, .toolbarButton]
    }
}

extension AnimePlayerReducer.State {
    var canShowPlayerOverlay: Bool {
        showPlayerOverlay || playerStatus == .paused || selectedSidebar != nil
    }

    var showSettingsOverlay: Bool? {
        if case .settings = selectedSidebar {
            return true
        }
        return nil
    }

    var showSubtitlesOverlay: Bool? {
        if case .subtitles = selectedSidebar {
            return true
        }
        return nil
    }
}
