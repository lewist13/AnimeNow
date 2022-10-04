//
//  VideoPlayerV2View.swift
//  Anime Now!
//
//  Created Erik Bautista on 10/1/22.
//  Copyright © 2022. All rights reserved.
//

import SwiftUI
import ComposableArchitecture

struct VideoPlayerV2View: View {
    let store: Store<VideoPlayerV2Core.State, VideoPlayerV2Core.Action>

    var body: some View {
        AVPlayerView(
            store: store.scope(
                state: \.player,
                action: VideoPlayerV2Core.Action.player
            )
        )
        .overlay(errorOverlay)
        .overlay(playerControlsOverlay)
        .overlay(statusOverlay)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        .statusBar(hidden: true)
        .ignoresSafeArea(edges: .vertical)
        .background(Color.black.edgesIgnoringSafeArea(.all))
        .onTapGesture {
            ViewStore(store.stateless).send(.playerTapped)
        }
        .onAppear {
            ViewStore(store.stateless).send(.onAppear)
        }
    }
}

// MARK: Error Overlay

extension VideoPlayerV2View {
    @ViewBuilder
    var errorOverlay: some View {
        WithViewStore(store.scope(state: \.error)) { errorState in
            switch errorState.state {
            case .some(.failedToLoadEpisodes):
                Text("Failed to load episodes")
            case .some(.failedToFindProviders):
                Text("No providers available for this episode.")
            case .some(.failedToLoadSources):
                Text("Failed to load sources")
            case .none:
                EmptyView()
            }
        }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .background(Color.black)
    }
}

// MARK: Status Overlay

extension VideoPlayerV2View {
    private struct VideoStatusViewState: Equatable {
        let status: VideoPlayerV2Core.State.Status?
        let showingPlayerControls: Bool

        init(_ state: VideoPlayerV2Core.State) {
            self.status = state.statusState
            self.showingPlayerControls = state.showPlayerOverlay
        }
    }

    @ViewBuilder
    var statusOverlay: some View {
        WithViewStore(
            store.scope(state: VideoStatusViewState.init)
        ) { viewState in
            switch viewState.status {
            case .some(.loading):
                ProgressView()
                    .colorInvert()
                    .brightness(1)
                    .scaleEffect(1.5)
                    .frame(width: 24, height: 24, alignment: .center)
            case .some(.playing), .some(.paused):
                if viewState.showingPlayerControls {
                    Image(systemName: viewState.status == .playing ? "pause.fill" : "play.fill")
                        .foregroundColor(Color.white)
                        .font(.title)
                        .frame(width: 48, height: 48)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            ViewStore(store.stateless).send(.togglePlayback)
                        }
                }
            case .some(.replay):
                Image(systemName: "arrow.counterclockwise")
                    .foregroundColor(Color.white)
                    .font(.title)
                    .frame(width: 48, height: 48)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        ViewStore(store.stateless).send(.replayTapped)
                    }
            case .none:
                EmptyView()
            }
        }
    }
}

// MARK: Player Controls Overlay

extension VideoPlayerV2View {
    @ViewBuilder
    var playerControlsOverlay: some View {
        GeometryReader { proxy in
            WithViewStore(
                store.scope(
                    state: \.showPlayerOverlay
                )
            ) { showPlayerOverlay in
                if showPlayerOverlay.state {
                    VStack(spacing: 0) {
                        topPlayerItems
                        Spacer()
                        videoInfoWithActions
                        bottomPlayerItems
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(max(proxy.safeAreaInsets.leading, proxy.safeAreaInsets.trailing))
                    .padding(max(proxy.safeAreaInsets.leading, proxy.safeAreaInsets.trailing) == 0 ? 24 : 0)
                    .ignoresSafeArea()
                    .background(Color.black.opacity(0.5).ignoresSafeArea())
                }
            }
        }
    }
}

// MARK: Top Player Items

extension VideoPlayerV2View {
    @ViewBuilder
    var topPlayerItems: some View {
        HStack {
            closeButton
        }
            .transition(.move(edge: .top))
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    @ViewBuilder
    var closeButton: some View {
        Circle()
            .foregroundColor(Color.white)
            .overlay(
                Image(
                    systemName: "xmark"
                )
                .foregroundColor(Color.black)
                .font(.callout.weight(.black))
            )
            .frame(width: 30, height: 30)
            .contentShape(Rectangle())
            .onTapGesture {
                ViewStore(store.stateless).send(.closeButtonTapped)
            }
    }
}

extension VideoPlayerV2View {

    @ViewBuilder
    var videoInfoWithActions: some View {
        HStack(alignment: .bottom) {
            animeEpisodeTitleInfo
            Spacer()
            playerOptionsButton
        }
    }
}

// MARK: Anime Info

extension VideoPlayerV2View {
    private struct AnimeInfoViewState: Equatable {
        let title: String
        let header: String?
        let isMovie: Bool

        init(_ state: VideoPlayerV2Core.State) {
            self.title = state.anime.format == .movie ? state.anime.title : (state.episode?.name ?? "Untitled")
            self.header = state.anime.format == .tv ? "E\(state.episode?.number ?? 0) \u{2022} \(state.anime.title)" : nil
            self.isMovie = state.anime.format == .movie
        }
    }

    @ViewBuilder
    var animeEpisodeTitleInfo: some View {
        WithViewStore(
            store.scope(
                state: AnimeInfoViewState.init
            )
        ) { viewState in
            VStack(alignment: .leading, spacing: 0) {
                if let header = viewState.header {
                    Text(header)
                        .font(.callout.bold())
                        .foregroundColor(.white.opacity(0.85))
                        .lineLimit(1)
                }

                HStack {
                    Text(viewState.state.title)
                        .font(.largeTitle.bold())
                        .lineLimit(1)

                    if !viewState.isMovie {
                        Image(systemName: "chevron.compact.right")
                            .font(.body.weight(.black))
                    }
                }
            }
            .foregroundColor(.white)
            .contentShape(Rectangle())
            .onTapGesture {
                if !viewState.isMovie {
                    viewState.send(.showMoreEpisodesTapped)
                }
            }
        }
    }
}

// MARK: Player Options Buttons

extension VideoPlayerV2View {
    @ViewBuilder
    var playerOptionsButton: some View {
        HStack(spacing: 16) {
            airplayButton
            subtitlesButton
            sourcesButton
        }
    }

    @ViewBuilder
    var sourcesButton: some View {
        Button {
//            ViewStore(store.stateless).send(.tappedSourcesSidebar)
        } label: {
            Image("play.rectangle.on.rectangle.fill")
                .foregroundColor(Color.white)
                .font(.title3)
        }
    }

    @ViewBuilder
    var subtitlesButton: some View {
        Button {
        } label: {
            Image(
                systemName: "captions.bubble.fill"
            )
            .foregroundColor(Color.white)
            .font(.title3)
        }
    }

    @ViewBuilder
    var airplayButton: some View {
        AirplayRouterPickerView()
            .fixedSize()
    }
}


// MARK: Bottom Player Items

extension VideoPlayerV2View {
    private struct DurationViewState {
        let progress: Double?
        let maxDuration: Double?
    }

    @ViewBuilder
    var bottomPlayerItems: some View {
        VStack {
            SeekbarView(
                progress: .constant(0.5),
                preloaded: 0.0
            ) { isEditing in
                
            }
            .frame(height: 12)
            .padding(.top, 8)

            HStack(spacing: 4) {
                Text(
                    "--:--"
                )
                Text("/")
                Text(
                    "--:--"
                )
                Spacer()
            }
            .foregroundColor(.white)
            .font(.footnote.bold().monospacedDigit())
        }
    }
}

// MARK: Sidebar Views

extension VideoPlayerV2View {
//    @ViewBuilder
//    var sidepanelView: some View {
//        IfLetStore(
//            store.scope(state: \.sidebarRoute)
//        ) { sidebarStore in
//            WithViewStore(sidebarStore) { sidebarViewStore in
//                VStack {
//                    HStack(alignment: .center) {
//                        Text(sidebarViewStore.state.stringVal)
//                            .foregroundColor(Color.white)
//                            .font(.title2)
//                            .bold()
//                        Spacer()
//                        sidebarCloseButton
//                    }
//
//                    switch sidebarViewStore.state {
//                    case .episodes:
//                        SidebarEpisodesView(
//                            store: store.scope(
//                                state: \.episodesState,
//                                action: VideoPlayerCore.Action.episodes
//                            )
//                        )
//                    case .sources:
//                        SidebarSourcesView(
//                            store: store.scope(
//                                state: \.sourcesState,
//                                action: VideoPlayerCore.Action.sources
//                            )
//                        )
//                    }
//                }
//                .padding([.horizontal, .top])
//            }
//            .aspectRatio(1.0, contentMode: .fit)
//            .frame(maxHeight: .infinity)
//            .background(
//                BlurView(style: .systemThickMaterialDark)
//            )
//            .cornerRadius(18)
//            .padding(.vertical, 24)
//            .transition(.move(edge: .trailing).combined(with: .opacity))
//        }
//        .frame(
//            maxWidth: .infinity,
//            maxHeight: .infinity,
//            alignment: .trailing
//        )
//    }
//
//    @ViewBuilder
//    var sidebarCloseButton: some View {
//        Circle()
//            .foregroundColor(Color.white)
//            .overlay(
//                Image(systemName: "xmark")
//                    .font(.system(size: 12).weight(.black))
//                    .foregroundColor(Color.black.opacity(0.75))
//            )
//            .frame(width: 24, height: 24)
//            .contentShape(Rectangle())
//            .onTapGesture {
//                ViewStore(store.stateless).send(.closeSidebar)
//            }
//    }
}

// MARK: Player Controls

struct VideoPlayerV2View_Previews: PreviewProvider {
    static var previews: some View {
        if #available(iOS 15.0, *) {
            VideoPlayerV2View(
                store: .init(
                    initialState: .init(
                        anime: .narutoShippuden,
                        episodes: .init(uniqueElements: Episode.demoEpisodes),
                        selectedEpisode: Episode.demoEpisodes.first!.id
                    ),
                    reducer: VideoPlayerV2Core.reducer,
                    environment: .init(
                        animeClient: .mock,
                        mainQueue: .main.eraseToAnyScheduler(),
                        mainRunLoop: .main.eraseToAnyScheduler(),
                        repositoryClient: RepositoryClientMock.shared,
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
