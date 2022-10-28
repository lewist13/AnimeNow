//
//  AnimePlayerView.swift
//  Anime Now!
//
//  Created by ErrorErrorError on 10/1/22.
//  Copyright © 2022. All rights reserved.
//

import SwiftUI
import ComposableArchitecture
import AVFoundation


struct AnimePlayerView: View {
    let store: Store<AnimePlayerReducer.State, AnimePlayerReducer.Action>

    struct VideoPlayerState: Equatable {
        let url: URL?
        let action: VideoPlayer.Action?

        init(_ state: AnimePlayerReducer.State) {
            url = state.source?.url
            action = state.playerAction
        }
    }

    var body: some View {
        WithViewStore(
            store,
            observe: VideoPlayerState.init
        ) { viewStore in
            VideoPlayer(
                url: viewStore.url,
                action: viewStore.binding(\.$playerAction, as: \.action)
            )
            .onStatusChanged { status in
                viewStore.send(.playerStatus(status))
            }
            .onProgressChanged { progress in
                viewStore.send(.playerProgress(progress))
            }
            .onDurationChanged { duration in
                viewStore.send(.playerDuration(duration))
            }
            .onBufferChanged { buffer in
                viewStore.send(.playerBuffer(buffer))
            }
            .onPlayedToTheEnd {
                viewStore.send(.playerPlayedToEnd)
            }
            .onPictureInPictureStatusChanged { status in
                viewStore.send(.playerPiPStatus(status))
            }
            .onSubtitlesChanged { selection in
//                viewStore.send(.playerSubtitles(selection))
            }
            .onSubtitleSelectionChanged { selected in
//                viewStore.send(.playerSelectedSubtitle(selected))
            }
            .onVolumeChanged { volume in
                viewStore.send(.playerVolume(volume))
            }
            .onAppear {
                viewStore.send(.onAppear)
            }
        }
        .frame(
            maxWidth: .infinity,
            maxHeight: .infinity,
            alignment: .center
        )
        .onTapGesture {
            ViewStore(store.stateless).send(.playerTapped)
        }
        .overlay(errorOverlay)
        .overlay(playerControlsOverlay)
        .ignoresSafeArea(edges: .vertical)
        .background(Color.black.edgesIgnoringSafeArea(.all))
    }
}

// MARK: Loading View

extension AnimePlayerView {
    @ViewBuilder
    var loadingView: some View {
        Rectangle()
            .foregroundColor(.clear)
            .overlay(
                ProgressView()
                    .colorInvert()
                    .brightness(1)
                    .scaleEffect(1.5)
            )
            .frame(width: 48, height: 48)
    }
}

// MARK: Error Overlay

extension AnimePlayerView {
    @ViewBuilder
    var errorOverlay: some View {
        WithViewStore(
            store,
            observe: { $0.status }
        ) { status in
            switch status.state {
            case .some(.error(let description)):
                buildErrorView(description)
            default:
                EmptyView()
            }
        }
    }

    @ViewBuilder
    private func buildErrorView(_ description: String) -> some View {
        HStack {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 42))
                .foregroundColor(Color.red)

            VStack(alignment: .leading) {
                Text("Error")
                    .font(.title)
                    .bold()

                Text(description)
                    .font(.callout)
                    .multilineTextAlignment(.leading)
            }
            .frame(width: 300)
        }
        .foregroundColor(.white)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        .background(Color.black.allowsHitTesting(false))
    }
}

// MARK: Anime Info

extension AnimePlayerView {
    private struct AnimeInfoViewState: Equatable {
        let title: String
        let header: String?

        init(_ state: AnimePlayerReducer.State) {
            let isMovie = state.anime.format == .movie

            if isMovie {
                self.title = state.anime.title
                self.header = (state.episodes.value?.count ?? 0) > 1 ? "E\(state.selectedEpisode)" : nil
            } else {
                self.title = state.episode?.title ?? "Loading..."
                self.header = "E\(state.selectedEpisode) \u{2022} \(state.anime.title)"
            }
        }
    }

    @ViewBuilder
    var animeInfoView: some View {
        WithViewStore(
            store,
            observe: AnimeInfoViewState.init
        ) { viewState in
            VStack(
                alignment: .leading,
                spacing: 0
            ) {
                HStack {
                    Text(viewState.state.title)
                        .font(DeviceUtil.isPhone ? .title2 : .title)
                        .bold()
                        .lineLimit(1)
                }

                if let header = viewState.header {
                    Text(header)
                        .font(DeviceUtil.isPhone ? .footnote : .callout)
                        .bold()
                        .foregroundColor(.init(white: 0.85))
                        .lineLimit(1)
                }
            }
            .foregroundColor(.white)
        }
    }
}

// MARK: Skip Button

extension AnimePlayerView {
    struct SkipActionViewState: Equatable {
        let canShowButton: Bool
        let action: AnimePlayerReducer.State.ActionType?

        init(_ state: AnimePlayerReducer.State) {
            self.action = state.skipAction
            self.canShowButton = state.selectedSidebar == nil && self.action != nil
        }
    }

    @ViewBuilder
    var skipButton: some View {
        WithViewStore(
            store,
            observe: SkipActionViewState.init
        ) { viewState in
            Group {
                if viewState.state.canShowButton {
                    switch viewState.state.action {
                    case .some(.skipRecap(to: let end)),
                            .some(.skipOpening(to: let end)),
                            .some(.skipEnding(to: let end)):

                        actionButtonBase(
                            "forward.fill",
                            viewState.state.action?.title ?? "",
                            .white,
                            .init(white: 0.25)
                        )
                            .onTapGesture {
                                viewState.send(.startSeeking)
                                viewState.send(.seeking(to: end))
                                viewState.send(.stopSeeking)
                            }

                    case .some(.nextEpisode(let id)):
                        actionButtonBase(
                            "play.fill",
                            viewState.state.action?.title ?? "",
                            .black,
                            .white
                        )
                            .onTapGesture {
                                viewState.send(.selectEpisode(id))
                            }
                    case .none:
                        EmptyView()
                    }
                }
            }
            .frame(
                maxWidth: .infinity,
                alignment: .trailing
            )
            .transition(.move(edge: .trailing).combined(with: .opacity))
            .animation(
                .easeInOut(duration: 0.5),
                value: viewState.canShowButton || viewState.action != nil
            )
        }
        .padding(.vertical, 4)
    }

    @ViewBuilder
    private func actionButtonBase(
        _ image: String,
        _ title: String,
        _ textColor: Color,
        _ background: Color
    ) -> some View {
        HStack {
            Image(systemName: image)
            Text(title)
        }
            .font(.system(size: 13).weight(.heavy))
            .foregroundColor(textColor)
            .padding(12)
            .background(background)
            .cornerRadius(12)
            .shadow(color: Color.gray.opacity(0.25), radius: 6)
            .contentShape(Rectangle())
    }
}

// MARK: Dismiss Button

extension AnimePlayerView {
    @ViewBuilder
    var dismissButton: some View {
        Image(
            systemName: "chevron.backward"
        )
        .foregroundColor(Color.white)
        .font(.title3.weight(.heavy))
        .frame(width: 42, height: 42, alignment: .center)
        .contentShape(Rectangle())
        .onTapGesture {
            ViewStore(store.stateless).send(.closeButtonTapped)
        }
    }
}

// MARK: Progress

extension AnimePlayerView {
    struct ProgressViewState: Equatable {
        let progress: Double
        let duration: Double
        let buffered: Double

        var isLoaded: Bool {
            duration != .zero
        }

        var progressWithDuration: Double? {
            if isLoaded {
                return progress * duration
            }
            return nil
        }

        init(_ state: AnimePlayerReducer.State) {
            self.duration = state.playerDuration
            self.progress = state.playerProgress
            self.buffered = state.playerBuffered
        }
    }
}

// MARK: Player Options Buttons

extension AnimePlayerView {

    @ViewBuilder
    var settingsButton: some View {
        Image(systemName: "gearshape.fill")
            .foregroundColor(Color.white)
            .font(.title2)
            .padding(4)
            .contentShape(Rectangle())
            .onTapGesture {
                ViewStore(store.stateless).send(.showSettingsSidebar)
            }
    }

    @ViewBuilder
    var subtitlesButton: some View {
        EmptyView()
//        WithViewStore(
//            store.scope(
//                state: \.playerSubtitles
//            )
//        ) { viewStore in
//            if let count = viewStore.state?.options.count, count > 0 {
//                Image(systemName: "captions.bubble.fill")
//                    .foregroundColor(Color.white)
//                    .font(.title2)
//                    .padding(4)
//                    .contentShape(Rectangle())
//                    .onTapGesture {
//                        viewStore.send(.showSubtitlesSidebar)
//                    }
//            }
//        }
    }

    @ViewBuilder
    var airplayButton: some View {
        AirplayView()
            .fixedSize()
    }

    @ViewBuilder
    var nextEpisodeButton: some View {
        WithViewStore(
            store,
            observe: { $0.nextEpisode }
        ) { viewState in
            Image(systemName: "forward.end.fill")
                .foregroundColor(viewState.state != nil ? Color.white : Color.gray)
                .font(.title2)
                .padding(4)
                .contentShape(Rectangle())
                .onTapGesture {
                    if let nextEpisode = viewState.state {
                        viewState.send(.selectEpisode(nextEpisode.id))
                    }
                }
                .disabled(viewState.state == nil)
        }
    }

    @ViewBuilder
    var episodesButton: some View {
        WithViewStore(
            store,
            observe: { $0.episodes }
        ) { viewState in
            if let episodes = viewState.state.value, episodes.count > 1 {
                Image("play.rectangle.on.rectangle.fill")
                    .foregroundColor(.white)
                    .font(.title2)
                    .padding(4)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        viewState.send(.showEpisodesSidebar)
                    }
            }
        }
    }
}

struct VideoPlayerView_Previews: PreviewProvider {
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
