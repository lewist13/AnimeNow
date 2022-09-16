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

    var body: some View {
        ZStack {
            AVPlayerView(
                store: store.scope(
                    state: \.avPlayerState,
                    action: VideoPlayerCore.Action.player
                )
            )
            .ignoresSafeArea()

            playerOverlay
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .statusBar(hidden: true)
        .onAppear {
            ViewStore(store.stateless).send(.begin)
        }
    }
}

extension VideoPlayerView {
    @ViewBuilder
    var playerOverlay: some View {
        GeometryReader { geometry in
            VStack(alignment: .leading) {
                Spacer()
                playerControls
            }
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
                .ignoresSafeArea()
            )
        }
    }
}

// MARK: Episode Info

//extension VideoPlayerView {
//    @ViewBuilder
//    var episodeInfo: some View {
//    }
//}

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
            store.scope(state: \.playerStatus)
        ) { playerStateViewStore in
            Button {
                playerStateViewStore.send(.togglePlayback)
            } label: {
                Image(
                    systemName: playerStateViewStore.state == .playing ? "pause.fill" : "play.fill"
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
            Text("0:00:00")
            Slider(
                value: .constant(5),
                in: 0...10
            )
            Text("1:00:00")
        }
        .foregroundColor(.white)
        .font(.footnote.monospacedDigit())
    }

    @ViewBuilder
    var settingsButton: some View {
        Button {
        } label: {
            Image(systemName: "gearshape")
                .foregroundColor(Color.white)
        }
    }
}

struct VideoPlayerView_Previews: PreviewProvider {
    static var previews: some View {
        if #available(iOS 15.0, *) {
            VideoPlayerView(
                store: .init(
                    initialState: .init(
                        source: .mock
                    ),
                    reducer: VideoPlayerCore.reducer,
                    environment: .init(
                        mainQueue: .main
                    )
                )
            )
//            .previewInterfaceOrientation(.landscapeRight)
        } else {
            // Fallback on earlier versions
        }
    }
}
