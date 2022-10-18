//
//  AnimeNowVideoPlayer.swift
//  Anime Now!
//
//  Created by ErrorErrorError on 10/1/22.
//  Copyright © 2022. All rights reserved.
//

import SwiftUI
import ComposableArchitecture
import AVFoundation


struct AnimeNowVideoPlayer: View {

    let store: Store<AnimeNowVideoPlayerCore.State, AnimeNowVideoPlayerCore.Action>

    struct VideoPlayerState: Equatable {
        let url: URL?
        let action: VideoPlayer.Action?
        let progress: Double

        init(_ state: AnimeNowVideoPlayerCore.State) {
            url = state.source?.url
            action = state.playerAction
            progress = state.playerProgress
        }
    }

    var body: some View {
        WithViewStore(
            store.scope(
                state: VideoPlayerState.init
            )
        ) { viewStore in
            VideoPlayer(
                url: viewStore.url,
                action: viewStore.binding(\.$playerAction, as: \.action),
                progress: viewStore.binding(\.$playerProgress, as: \.progress)
            )
            .onStatusChanged { status in
                viewStore.send(.playerStatus(status))
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
                viewStore.send(.playerSubtitles(selection))
            }
            .onSubtitleSelectionChanged { selected in
                viewStore.send(.playerSelectedSubtitle(selected))
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

// MARK: Error Overlay

extension AnimeNowVideoPlayer {
    @ViewBuilder
    var errorOverlay: some View {
        WithViewStore(store.scope(state: \.status)) { status in
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

// MARK: Skip Button

extension AnimeNowVideoPlayer {
    struct SkipActionViewState: Equatable {
        let canShowButton: Bool
        let action: AnimeNowVideoPlayerCore.State.ActionType?

        init(_ state: AnimeNowVideoPlayerCore.State) {
            self.action = state.skipAction
            self.canShowButton = state.selectedSidebar == nil && self.action != nil
        }
    }

    @ViewBuilder
    var skipButton: some View {
        WithViewStore(
            store.scope(
                state: SkipActionViewState.init
            )
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

extension AnimeNowVideoPlayer {
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

// MARK: Player Options Buttons

extension AnimeNowVideoPlayer {

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
        WithViewStore(
            store.scope(
                state: \.playerSubtitles
            )
        ) { viewStore in
            if let count = viewStore.state?.options.count, count > 0 {
                Image(systemName: "captions.bubble.fill")
                    .foregroundColor(Color.white)
                    .font(.title2)
                    .padding(4)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        viewStore.send(.showSubtitlesSidebar)
                    }
            }
        }
    }

    @ViewBuilder
    var airplayButton: some View {
        AirplayView()
            .fixedSize()
    }

    @ViewBuilder
    var nextEpisodeButton: some View {
        WithViewStore(
            store.scope(state: \.nextEpisode)
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
            store.scope(state: \.episodes)
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
        if #available(iOS 15.0, *) {
            AnimeNowVideoPlayer(
                store: .init(
                    initialState: .init(
                        anime: .narutoShippuden,
                        episodes: .init(uniqueElements: Episode.demoEpisodes),
                        selectedEpisode: Episode.demoEpisodes.first!.id
                    ),
                    reducer: AnimeNowVideoPlayerCore.reducer,
                    environment: .init(
                        animeClient: .mock,
                        mainQueue: .main.eraseToAnyScheduler(),
                        mainRunLoop: .main.eraseToAnyScheduler(),
                        repositoryClient: RepositoryClientMock.shared,
                        userDefaultsClient: .mock
                    )
                )
            )
        } else {
            // Fallback on earlier versions
        }
    }
}
