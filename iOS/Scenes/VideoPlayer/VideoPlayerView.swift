//
//  VideoPlayerView.swift
//  Anime Now! (iOS)
//
//  Created by Erik Bautista on 9/15/22.
//

import SwiftUI
import ComposableArchitecture

struct VideoPlayerView: View {
    let store: Store<VideoPlayerCore.State, VideoPlayerCore.Action>

    struct ViewState: Equatable {
        let isLoaded: Bool
        let isPlaying: Bool
        let isBuffering: Bool
        let currentTime: Double
        let duration: Double

        init(state: VideoPlayerCore.State) {
            self.isLoaded = state.avPlayerState.status == .readyToPlay
            self.isPlaying = state.avPlayerState.timeStatus == .playing
            self.isBuffering = state.avPlayerState.timeStatus == .waitingToPlayAtSpecifiedRate
            self.currentTime = state.avPlayerState.currentTime.seconds
            self.duration = state.avPlayerState.duration?.seconds ?? 0
        }
    }

    var body: some View {
        ZStack {
            AVPlayerView(
                store: store.scope(
                    state: \.avPlayerState,
                    action: VideoPlayerCore.Action.player
                )
            )
            .onTapGesture {
                ViewStore(store.stateless).send(.tappedPlayer)
            }
            loadingView
            playerOverlay
        }
        .ignoresSafeArea()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black.ignoresSafeArea())
        .statusBar(hidden: true)
        .onAppear {
            ViewStore(store.stateless).send(.onAppear)
        }
    }
}

extension VideoPlayerView {
    @ViewBuilder
    var playerOverlay: some View {
        WithViewStore(
            store.scope(state: \.showingOverlay)
        ) { showingOverlayViewStore in
            if showingOverlayViewStore.state {
                GeometryReader { geometry in
                    VStack(alignment: .leading) {
                        topPlayerItems
                        Spacer()
                        playerControls
                    }
                    .padding()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(
                        LinearGradient(
                            colors: [
                                Color.black,
                                Color.clear,
                                Color.black
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        .opacity(0.5)
                    )
                }
            }
        }
    }

    @ViewBuilder
    var loadingView: some View {
        WithViewStore(
            store.scope(state: ViewState.init(state:))
        ) { viewState in
            if viewState.state.isBuffering || !viewState.state.isLoaded {
                ProgressView()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: Episode Info

//extension VideoPlayerView {
//    @ViewBuilder
//    var episodeInfo: some View {
//    }
//}

// MARK: Top Player Items

extension VideoPlayerView {
    @ViewBuilder
    var topPlayerItems: some View {
        HStack(alignment: .center, spacing: 18) {
            closeButton
        }
        .padding(.horizontal)
    }

    @ViewBuilder
    var closeButton: some View {
        WithViewStore(
            store.stateless
        ) { viewStore in
            Button {
                viewStore.send(.closeButtonPressed)
            } label: {
                Image(
                    systemName: "xmark"
                )
                .font(.body.weight(.black))
                .foregroundColor(Color.white)
            }
            .buttonStyle(BlurredButtonStyle())
            .clipShape(RoundedRectangle(cornerRadius: 16, style: RoundedCornerStyle.continuous))
        }
    }
}

// MARK: Player Controls

extension VideoPlayerView {
    @ViewBuilder
    var playerControls: some View {
        HStack(alignment: .center, spacing: 18) {
            playButton
            seekbarView
            settingsButton
        }
        .padding(.horizontal)
    }

    @ViewBuilder
    var playButton: some View {
        WithViewStore(
            store.scope(state: ViewState.init(state:))
        ) { viewState in
            Button {
                viewState.send(.togglePlayback)
            } label: {
                Image(
                    systemName: viewState.state.isPlaying ? "pause.fill" : "play.fill"
                )
                .foregroundColor(Color.white)
            }
            .buttonStyle(BlurredButtonStyle())
            .clipShape(RoundedRectangle(cornerRadius: 16, style: RoundedCornerStyle.continuous))
        }
    }

    @ViewBuilder
    var seekbarView: some View {
        HStack {
            WithViewStore(
                store.scope(
                    state: ViewState.init(state:)
                )
            ) { viewState in
                Text(viewState.state.duration > 0 ? viewState.state.currentTime.timeFormatted : "--:--")

                Slider(
                    value: .init(
                        get: { viewState.state.currentTime },
                        set: { viewState.send(.slidingSeeker($0)) }
                    ),
                    in: 0...viewState.state.duration,
                    onEditingChanged: { editing in
                        viewState.send(editing ? .startSeeking : .doneSeeking)
                    }
                )
                .disabled(viewState.state.duration == 0)
                .padding(.horizontal)

                Text(
                    viewState.state.duration > 0 ? viewState.state.duration.timeFormatted : "--:--"
                )
            }
        }
        .foregroundColor(.white)
        .font(.footnote.monospacedDigit())
        .padding(4)
        .padding(.horizontal)
        .background(BlurView(style: .systemThinMaterialDark))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: RoundedCornerStyle.continuous))
    }

    @ViewBuilder
    var settingsButton: some View {
        Button {
        } label: {
            Image(
                systemName: "gearshape"
            )
            .foregroundColor(Color.white)
        }
        .buttonStyle(BlurredButtonStyle())
        .clipShape(RoundedRectangle(cornerRadius: 16, style: RoundedCornerStyle.continuous))
    }
}

struct VideoPlayerView_Previews: PreviewProvider {
    static var previews: some View {
        if #available(iOS 15.0, *) {
            VideoPlayerView(
                store: .init(
                    initialState: .init(
                        sources: EpisodeSource.mock
                    ),
                    reducer: VideoPlayerCore.reducer,
                    environment: .init(
                        mainQueue: .main.eraseToAnyScheduler(),
                        mainRunLoop: .main.eraseToAnyScheduler(),
                        userDefaultsClient: .mock
                    )
                )
            )
            .previewInterfaceOrientation(.landscapeRight)
        } else {
            // Fallback on earlier versions
        }
    }
}
