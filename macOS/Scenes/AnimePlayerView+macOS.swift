//
//  AnimePlayerView+macOS.swift
//  Anime Now! (macOS)
//
//  Created by ErrorErrorError on 10/16/22.
//

import SwiftUI
import ComposableArchitecture

extension AnimePlayerView {
    @ViewBuilder
    var playerControlsOverlay: some View {
        WithViewStore(
            store.scope(
                state: \.showPlayerOverlay
            )
        ) { showPlayerOverlay in
            GeometryReader { proxy in
                VStack(spacing: 0) {
                    if showPlayerOverlay.state {
                        topPlayerItems
                    }
                    Spacer()
                    skipButton
                    if showPlayerOverlay.state {
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
                        .opacity(showPlayerOverlay.state ? 1 : 0)
                )
            }
        }
        .onHover { isHovering in
            NSApp.mainWindow?.standardWindowButton(.zoomButton)?.isHidden = !isHovering
            NSApp.mainWindow?.standardWindowButton(.closeButton)?.isHidden = !isHovering
            NSApp.mainWindow?.standardWindowButton(.miniaturizeButton)?.isHidden = !isHovering
            ViewStore(store.stateless).send(
                .isHoveringPlayer(isHovering)
            )
        }
        .overlay(statusOverlay)
        .overlay(sidebarOverlay)
    }
}

// MARK: Status Overlay

extension AnimePlayerView {
    @ViewBuilder
    var statusOverlay: some View {
        WithViewStore(
            store,
            observe: { $0.status == .loading }
        ) { viewState in
            if viewState.state {
                loadingView
            }
        }
    }
}

// MARK: Sidebar Items

extension AnimePlayerView {
    @ViewBuilder
    var sidebarOverlay: some View {
        EmptyView()
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
            airplayButton
        }
        .frame(maxWidth: .infinity)
        .transition(.opacity)
    }
}

// MARK: Bottom Player Items

extension AnimePlayerView {
    @ViewBuilder
    var bottomPlayerItems: some View {
        VStack {
            sliderView
            HStack(spacing: 22) {
                playStateView
                volumeButton
                nextEpisodeButton
                durationView
                Spacer()
                episodesButton
                settingsButton
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
    var sliderView: some View {
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
                    viewState.canShow ? viewState.duration.timeFormatted : "--:--"
                )
            }
            .foregroundColor(.white)
            .font(.body.bold().monospacedDigit())
        }
    }

    private enum VolumeViewState: Equatable {
        case muted
        case low
        case med
        case high

        init(_ state: AnimePlayerReducer.State) {
            self = .med
        }

        var image: String {
            switch self {
            case .muted:
                return "speaker.slash.fill"
            case .low:
                return "speaker.wave.1.fill"
            case .med:
                return "speaker.wave.2.fill"
            case .high:
                return "speaker.wave.3.fill"
            }
        }
    }

    @ViewBuilder
    var volumeButton: some View {
        WithViewStore(
            store,
            observe: VolumeViewState.init
        ) { viewState in
            Image(
                systemName: viewState.image
            )
                .font(.title2.bold())
                .contentShape(Rectangle())
                .onTapGesture {
                }
                .foregroundColor(Color.white)
        }
    }

    @ViewBuilder
    var fullscreenButton: some View {
        WithViewStore(
            store,
            observe: { _ in false }
        ) { viewState in
            Image(systemName: viewState.state ? "pause.fill" : "arrow.up.backward.and.arrow.down.forward")
                .font(.title2.bold())
                .contentShape(Rectangle())
                .onTapGesture {
                }
                .foregroundColor(Color.white)
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
