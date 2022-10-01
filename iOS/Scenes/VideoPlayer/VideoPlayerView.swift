//
//  VideoPlayerView.swift
//  Anime Now! (iOS)
//
//  Created by Erik Bautista on 9/15/22.
//

import SwiftUI
import ComposableArchitecture
import Kingfisher
import SwiftUINavigation

struct VideoPlayerView: View {
    let store: Store<VideoPlayerCore.State, VideoPlayerCore.Action>

    struct ViewState: Equatable {
        let showPlayerControlsOverlay: Bool
        let hasLoaded: Bool
        let isPlaying: Bool
        let isBuffering: Bool
        let currentTime: Double
        let duration: Double
        let sidebar: SidebarRoute?

        let animeName: String
        let animeFormat: Anime.Format
        let episodeName: String
        let episodeNumber: Int

        init(state: VideoPlayerCore.State) {
            self.hasLoaded = state.playerState.status == .readyToPlay
            self.showPlayerControlsOverlay = state.showPlayerOverlay
            self.isPlaying = state.playerState.timeStatus == .playing
            self.isBuffering = state.sourcesState.sources == .loading || state.playerState.timeStatus == .waitingToPlayAtSpecifiedRate
            self.currentTime = state.playerState.currentTime.seconds
            self.duration = state.playerState.duration?.seconds ?? 0
            self.sidebar = state.sidebarRoute
            self.animeName = state.anime.title
            self.animeFormat = state.anime.format
            self.episodeName = state.episodesState.episode?.name ?? "Untitled"
            self.episodeNumber = state.episodesState.episode?.number ?? 0
        }
    }

    var body: some View {
        AVPlayerView(
            store: store.scope(
                state: \.playerState,
                action: VideoPlayerCore.Action.player
            )
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        .onTapGesture {
            ViewStore(store.stateless).send(.tappedPlayerBounds)
        }
        .overlay(playerOverlay)
        .overlay(statusButton)
        .overlay(sidepanelView)
        .statusBar(hidden: true)
        .ignoresSafeArea(edges: .vertical)
        .background(Color.black.edgesIgnoringSafeArea(.all))
        .onAppear {
            ViewStore(store.stateless).send(.onAppear)
        }
    }
}

// MARK: Player Overlay

extension VideoPlayerView {
    @ViewBuilder
    var playerOverlay: some View {
        WithViewStore(
            store.scope(state: ViewState.init)
        ) { showingOverlayViewStore in
            if showingOverlayViewStore.showPlayerControlsOverlay {
                VStack(alignment: .leading, spacing: 8) {
                    topPlayerItems
                    Spacer()
                    animeEpisodeInfo
                    bottomPlayerItems
                }
                .frame(
                    maxWidth: .infinity,
                    maxHeight: .infinity,
                    alignment: .center
                )
                .padding(.vertical, 24)
                .background(
                    LinearGradient(
                        colors: [
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
}

// MARK: Top Player Items

extension VideoPlayerView {
    @ViewBuilder
    var topPlayerItems: some View {
        HStack {
            closeButton
        }
            .transition(.move(edge: .top))
    }

    @ViewBuilder
    var closeButton: some View {
        Circle()
            .foregroundColor(Color.white)
            .padding(8)
            .overlay(
                Image(
                    systemName: "xmark"
                )
                .foregroundColor(Color.black)
                .font(.callout.weight(.black))
            )
            .frame(width: 46, height: 46)
            .contentShape(Rectangle())
            .onTapGesture {
                ViewStore(store.stateless).send(.notifyCloseButtonTapped)
            }
    }
}

// MARK: Sidebar Views

extension VideoPlayerView {
    @ViewBuilder
    var sidepanelView: some View {
        IfLetStore(
            store.scope(state: \.sidebarRoute)
        ) { sidebarStore in
            WithViewStore(sidebarStore) { sidebarViewStore in
                VStack {
                    HStack(alignment: .center) {
                        Text(sidebarViewStore.state.stringVal)
                            .foregroundColor(Color.white)
                            .font(.title2)
                            .bold()
                        Spacer()
                        sidebarCloseButton
                    }

                    switch sidebarViewStore.state {
                    case .episodes:
                        SidebarEpisodesView(
                            store: store.scope(
                                state: \.episodesState,
                                action: VideoPlayerCore.Action.episodes
                            )
                        )
                    case .sources:
                        SidebarSourcesView(
                            store: store.scope(
                                state: \.sourcesState,
                                action: VideoPlayerCore.Action.sources
                            )
                        )
                    }
                }
                .padding([.horizontal, .top])
            }
            .aspectRatio(1.0, contentMode: .fit)
            .frame(maxHeight: .infinity)
            .background(
                BlurView(style: .systemThickMaterialDark)
            )
            .cornerRadius(18)
            .padding(.vertical, 24)
            .transition(.move(edge: .trailing).combined(with: .opacity))
        }
        .frame(
            maxWidth: .infinity,
            maxHeight: .infinity,
            alignment: .trailing
        )
    }

    @ViewBuilder
    var sidebarCloseButton: some View {
        Circle()
            .foregroundColor(Color.white)
            .overlay(
                Image(systemName: "xmark")
                    .font(.system(size: 12).weight(.black))
                    .foregroundColor(Color.black.opacity(0.75))
            )
            .frame(width: 24, height: 24)
            .contentShape(Rectangle())
            .onTapGesture {
                ViewStore(store.stateless).send(.closeSidebar)
            }
    }
}

// MARK: Anime Episode Info

extension VideoPlayerView {
    @ViewBuilder
    var animeEpisodeInfo: some View {
        WithViewStore(
            store.scope(
                state: ViewState.init
            )
        ) { viewState in
            HStack(alignment: .bottom) {
                VStack(alignment: .leading) {
                    if viewState.animeFormat == .tv {
                        HStack(spacing: 4) {
                            Text(viewState.animeName)
                            Text("\u{2022}")
                            Text("E\(viewState.episodeNumber)")
                        }
                        .font(.callout.bold())
                        .foregroundColor(.white.opacity(0.8))
                    }

                    HStack {
                        Text(viewState.animeFormat == .tv ? viewState.episodeName : viewState.animeName)
                            .font(.title)
                            .bold()

                        if (viewState.animeFormat == .tv) {
                            Image(systemName: "chevron.compact.right")
                                .font(.body.weight(.black))
                        }
                    }
                }
                .foregroundColor(Color.white)
                .contentShape(Rectangle())
                .onTapGesture {
                    let viewStore = ViewStore(store)
                    if viewStore.anime.format == .tv {
                        viewStore.send(.tappedEpisodesSidebar)
                    }
                }

                Spacer()
                playerOptionsButton
            }
        }
    }
}

// MARK: Player Options Buttons

extension VideoPlayerView {
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
            ViewStore(store.stateless).send(.tappedSourcesSidebar)
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

// MARK: Player Controls

extension VideoPlayerView {
    @ViewBuilder
    var bottomPlayerItems: some View {
        LazyVStack(alignment: .leading) {
            seekbarView
                .frame(height: 14)
            progressInfo
        }
        .transition(.move(edge: .bottom))
    }

    @ViewBuilder
    var statusButton: some View {
        WithViewStore(
            store.scope(state: ViewState.init(state:))
        ) { viewState in
            if viewState.state.isBuffering || !viewState.state.hasLoaded {
                ProgressView()
                    .scaleEffect(1.5)
            } else if viewState.state.showPlayerControlsOverlay {
                Circle()
                    .foregroundColor(Color.clear)
                    .padding(8)
                    .overlay(
                        Image(
                            systemName: viewState.state.isPlaying ? "pause.fill" : "play.fill"
                        )
                        .foregroundColor(Color.white)
                        .font(.title)
                    )
                    .frame(width: 48, height: 48)
                    .contentShape(Circle())
                    .onTapGesture {
                        viewState.send(.togglePlayback)
                    }
            }
        }
        .frame(maxWidth: .infinity)
    }

    @ViewBuilder
    var seekbarView: some View {
        WithViewStore(
            store.scope(
                state: ViewState.init(state:)
            )
        ) { viewState in
            SeekbarView(
                progress: .init(
                    get: {
                        viewState.duration > 0 ?
                        viewState.currentTime / viewState.duration :
                        0
                    },
                    set: {
                        viewState.send(.slidingSeeker($0))
                    }
                ),
                preloaded: 0.0,
                onEditingCallback: { editing in
                    viewState.send(editing ? .startSeeking : .doneSeeking)
                }
            )
            .disabled(viewState.state.duration == 0)
        }
        .frame(maxWidth: .infinity)
    }

    @ViewBuilder
    var progressInfo: some View {
        WithViewStore(
            store.scope(state: ViewState.init)
        ) { viewState in
            HStack(spacing: 4) {
                Text(
                    viewState.duration > 0 ? viewState.currentTime.timeFormatted : "--:--"
                )
                Text("/")
                Text(
                    viewState.duration > 0 ? viewState.duration.timeFormatted : "--:--"
                )
            }
            .foregroundColor(.white)
            .font(.footnote.monospacedDigit())
        }
    }
}

struct VideoPlayerView_Previews: PreviewProvider {
    static var previews: some View {
        if #available(iOS 15.0, *) {
            VideoPlayerView(
                store: .init(
                    initialState: .init(
                        anime: .narutoShippuden,
                        episodes: .init(uniqueElements: Episode.demoEpisodes),
                        selectedEpisode: Episode.demoEpisodes.first!.id
                    ),
                    reducer: VideoPlayerCore.reducer,
                    environment: .init(
                        mainQueue: .main.eraseToAnyScheduler(),
                        animeClient: .mock,
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
