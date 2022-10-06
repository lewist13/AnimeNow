//
//  VideoPlayerView.swift
//  Anime Now!
//
//  Created Erik Bautista on 10/1/22.
//  Copyright © 2022. All rights reserved.
//

import SwiftUI
import ComposableArchitecture

struct VideoPlayerView: View {
    let store: Store<VideoPlayerCore.State, VideoPlayerCore.Action>

    var body: some View {
        WithViewStore(store.stateless) { viewStore in
            AVPlayerView(
                store: store.scope(
                    state: \.player,
                    action: VideoPlayerCore.Action.player
                )
            )
            .frame(
                maxWidth: .infinity,
                maxHeight: .infinity,
                alignment: .center
            )
            .overlay(
                HStack(spacing: 0) {
                    Color.clear
                        .contentShape(Rectangle())
                        .onTapGesture(count: 2) {
                            viewStore.send(.backwardsDoubleTapped)
                        }
                    Color.clear
                        .contentShape(Rectangle())
                        .onTapGesture(count: 2) {
                            viewStore.send(.forwardDoubleTapped)
                        }
                }
                    .frame(
                        maxWidth: .infinity,
                        maxHeight: .infinity,
                        alignment: .center
                    )
            )
            .onTapGesture {
                viewStore.send(.playerTapped)
            }
            .overlay(errorOverlay)
            .overlay(playerControlsOverlay)
            .overlay(statusOverlay)
            .overlay(sidebarOverlay)
            .statusBar(hidden: true)
            .ignoresSafeArea(edges: .vertical)
            .background(Color.black.edgesIgnoringSafeArea(.all))
            .onAppear {
                viewStore.send(.onAppear)
            }
        }
    }
}

// MARK: Error Overlay

extension VideoPlayerView {
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

// MARK: Status Overlay

extension VideoPlayerView {
    private struct VideoStatusViewState: Equatable {
        let status: VideoPlayerCore.State.Status?
        let showingPlayerControls: Bool

        init(_ state: VideoPlayerCore.State) {
            self.status = state.status
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
                        .font(.title.bold())
                        .frame(width: 48, height: 48)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            ViewStore(store.stateless).send(.togglePlayback)
                        }
                }
            case .some(.replay):
                Image(systemName: "arrow.counterclockwise")
                    .foregroundColor(Color.white)
                    .font(.title.bold())
                    .frame(width: 48, height: 48)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        ViewStore(store.stateless).send(.replayTapped)
                    }
            default:
                EmptyView()
            }
        }
    }
}

// MARK: Player Controls Overlay

extension VideoPlayerView {
    @ViewBuilder
    var playerControlsOverlay: some View {
        WithViewStore(
            store.scope(
                state: \.showPlayerOverlay
            )
        ) { showPlayerOverlay in
            if showPlayerOverlay.state {
                GeometryReader { proxy in
                    VStack(spacing: 0) {
                        topPlayerItems
                        Spacer()
                        videoInfoWithActions
                        bottomPlayerItems
                    }
                    .frame(
                        maxWidth: .infinity,
                        maxHeight: .infinity
                    )
                    .padding(safeAreaInsetPadding(proxy))
                    .ignoresSafeArea()
                    .background(
                        Color.black.opacity(0.5)
                            .ignoresSafeArea()
                            .allowsHitTesting(false)
                    )
                }
            }
        }
    }

    func safeAreaInsetPadding(_ proxy: GeometryProxy) -> Double {
        let safeArea = max(proxy.safeAreaInsets.leading, proxy.safeAreaInsets.trailing)

        if safeArea != 0 {
            return safeArea
        } else {
            return 24
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

// MARK: Anime Info + Player Options

extension VideoPlayerView {
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

extension VideoPlayerView {
    private struct AnimeInfoViewState: Equatable {
        let title: String
        let header: String?
        let isMovie: Bool

        init(_ state: VideoPlayerCore.State) {
            self.title = state.anime.format == .movie ? state.anime.title : (state.episode?.name ?? "Untitled")
            self.header = state.anime.format == .tv ? "E\(state.selectedEpisode) \u{2022} \(state.anime.title)" : nil
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
                    viewState.send(.showEpisodesSidebar)
                }
            }
        }
    }
}

// MARK: Player Options Buttons

extension VideoPlayerView {
    @ViewBuilder
    var playerOptionsButton: some View {
        HStack(spacing: 8) {
            airplayButton
            subtitlesButton
            settingsButton
        }
    }

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
        Image(systemName: "captions.bubble.fill")
            .foregroundColor(Color.white)
            .font(.title2)
            .padding(4)
            .contentShape(Rectangle())
    }

    @ViewBuilder
    var airplayButton: some View {
        AirplayRouterPickerView()
            .fixedSize()
    }
}

// MARK: Bottom Player Items

extension VideoPlayerView {
    private struct ProgressViewState: Equatable {
        let progress: Double
        let duration: Double?

        var progressWithDuration: Double? {
            if let duration = duration {
                return progress * duration
            }
            return nil
        }

        init(_ state: VideoPlayerCore.State) {
            self.progress = state.progress
            self.duration = state.duration
        }
    }

    @ViewBuilder
    var bottomPlayerItems: some View {
        WithViewStore(
            store.scope(
                state: ProgressViewState.init
            )
        ) { progressViewState in
            VStack {
                SeekbarView(
                    progress: .init(
                        get: {
                            progressViewState.progress
                        },
                        set: { progress in
                            progressViewState.send(.seeking(to: progress))
                        }
                    ),
                    preloaded: 0.0
                ) { isEditing in
                    progressViewState.send(isEditing ? .startSeeking : .stopSeeking)
                }
                .frame(height: 12)
                .padding(.top, 8)

                HStack(spacing: 4) {
                    Text(
                        progressViewState.progressWithDuration?.timeFormatted ?? "--:--"
                    )
                    Text("/")
                    Text(
                        progressViewState.duration?.timeFormatted ?? "--:--"
                    )
                    Spacer()
                }
                .foregroundColor(.white)
                .font(.footnote.bold().monospacedDigit())
            }
            .disabled(progressViewState.duration == nil)
        }
    }
}

// MARK: Sidebar

extension VideoPlayerView {
    @ViewBuilder
    var sidebarOverlay: some View {
        WithViewStore(
            store.scope(state: \.selectedSidebar)
        ) { selectedSidebar in
            Group {
                if let selectedSidebar = selectedSidebar.state {
                    GeometryReader { proxy in
                        VStack {
                            HStack(alignment: .center) {
                                Text("\(selectedSidebar.description)")
                                    .foregroundColor(Color.white)
                                    .font(.title2)
                                    .bold()
                                Spacer()
                                sidebarCloseButton
                            }

                            switch selectedSidebar {
                            case .episodes:
                                episodesSidebar
                            case .settings:
                                settingsSidebar
                            default:
                                EmptyView()
                            }
                        }
                        .padding([.horizontal, .top])
                        .frame(maxWidth: .infinity)
                        .background(
                            BlurView(style: .systemThickMaterialDark)
                        )
                        .cornerRadius(proxy.size.height / 16)
                    }
                    .frame(
                        maxWidth: .infinity,
                        maxHeight: .infinity,
                        alignment: .trailing
                    )
                    .padding(24)
                    .ignoresSafeArea()
                    .aspectRatio(8/9, contentMode: .fit)
                    .frame(
                        maxWidth: .infinity,
                        maxHeight: .infinity,
                        alignment: .trailing
                    )
                    .transition(.move(edge: .trailing).combined(with: .opacity))
                }
            }
            .gesture(
                DragGesture()
                    .onEnded { value in
                        // Drag right
                        if value.startLocation.x < value.location.x {
                            ViewStore(store.stateless).send(.closeSidebar)
                        }
                    }
            )
        }
    }

    @ViewBuilder
    var sidebarCloseButton: some View {
        Circle()
            .foregroundColor(Color.white)
            .overlay(
                Image(systemName: "xmark")
                    .font(.system(size: 12).weight(.black))
                    .foregroundColor(Color.black)
            )
            .frame(width: 28, height: 28)
            .contentShape(Rectangle())
            .onTapGesture {
                ViewStore(store.stateless).send(.closeSidebar)
            }
    }
}

// MARK: Episodes Sidebar

extension VideoPlayerView {
    private struct EpisodesSidebarViewState: Equatable {
        let episodes: IdentifiedArrayOf<Episode>
        let selectedEpisode: Episode.ID

        init(_ state: VideoPlayerCore.State) {
            self.episodes = state.episodes.value ?? []
            self.selectedEpisode = state.selectedEpisode
        }
    }

    @ViewBuilder
    var episodesSidebar: some View {
        ScrollViewReader { proxy in
            ScrollView(
                .vertical,
                showsIndicators: false
            ) {
                WithViewStore(
                    store.scope(
                        state: EpisodesSidebarViewState.init
                    )
                ) { viewStore in
                    LazyVStack {
                        ForEach(viewStore.episodes) { episode in
                            ThumbnailItemCompactView(
                                episode: episode
                            )
                            .overlay(
                                selectedOverlay(episode.id == viewStore.selectedEpisode)
                            )
                            .onTapGesture {
                                if viewStore.selectedEpisode != episode.id {
                                    viewStore.send(.selectEpisode(episode.id, saveProgress: true))
                                }
                            }
                            .id(episode.id)
                        }
                    }
                    .padding([.bottom])
                    .onAppear {
                        proxy.scrollTo(viewStore.selectedEpisode, anchor: .top)
                    }
                    .onChange(
                        of: viewStore.selectedEpisode
                    ) { newValue in
                        withAnimation {
                            proxy.scrollTo(newValue, anchor: .top)
                        }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func selectedOverlay(_ selected: Bool) -> some View {
        if selected {
            Text("Now Playing")
                .font(.caption2.weight(.heavy))
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.white)
                .foregroundColor(Color.black)
                .clipShape(Capsule())
                .shadow(
                    color: Color.black.opacity(0.5),
                    radius: 16,
                    x: 0,
                    y: 0
                )
                .frame(
                    maxWidth: .infinity,
                    maxHeight: .infinity,
                    alignment: .bottomLeading
                )
                .padding(6)
        }
    }
}

// MARK: Settings Sidebar

extension VideoPlayerView {
    private struct SettingsSidebarViewState: Equatable {
        let selectedSetting: VideoPlayerCore.Sidebar.SettingsState.Section?
        let selectedProvider: Episode.Provider.ID?
        let selectedSource: Source.ID?
        let isLoading: Bool

        private let providers: IdentifiedArrayOf<Episode.Provider>?
        private let sources: IdentifiedArrayOf<Source>?

        var provider: Episode.Provider? {
            if let selectedProvider = selectedProvider {
                return providers?[id: selectedProvider]
            }
            return nil
        }

        var selectableProviders: IdentifiedArrayOf<Episode.Provider> {
            if let providers = providers {
                var returnVal = IdentifiedArrayOf<Episode.Provider>()

                if let selectedProvider = self.provider {
                    returnVal.append(selectedProvider)
                }

                for provider in providers {
                    if !returnVal.contains(where: { $0.description == provider.description }) {
                        returnVal.append(provider)
                    }
                }

                return returnVal
            }

            return []
        }

        struct IdentifiedQuality: Equatable, Identifiable, CustomStringConvertible {
            let id: Source.ID
            let quality: Source.Quality

            init(_ source: Source) {
                self.id = source.id
                self.quality = source.quality
            }

            var description: String {
                quality.description
            }
        }

        var selectableQualities: IdentifiedArrayOf<IdentifiedQuality>? {
            if let sources = sources {
                return .init(uniqueElements: sources.map(IdentifiedQuality.init))
            }
            return nil
        }

        var quality: IdentifiedQuality? {
            if let selectedSource = selectedSource {
                return selectableQualities?[id: selectedSource]
            }
            return nil
        }

        struct IdentifiedAudio: Equatable, Identifiable, CustomStringConvertible {
            let id: Episode.Provider.ID
            let language: String

            init(_ provider: Episode.Provider) {
                self.id = provider.id
                self.language = (provider.dub ?? false) ? "English" : "Japanese"
            }

            var description: String {
                language
            }
        }

        var selectableAudio: IdentifiedArrayOf<IdentifiedAudio>? {
            if let providers = providers, let provider = provider {
                let filtered = providers.filter { $0.description == provider.description }
                return .init(uniqueElements: filtered.map(IdentifiedAudio.init))
            }
            return nil
        }

        var audio: IdentifiedAudio? {
            if let provider = provider, let languages = selectableAudio {
                return languages[id: provider.id]
            }
            return nil
        }

        init(_ state: VideoPlayerCore.State) {
            if case .settings(let item) = state.selectedSidebar {
                self.selectedSetting = item.selectedSection
            } else {
                self.selectedSetting = nil
            }
            self.isLoading = !state.episodes.finished || !state.sources.finished
            self.providers = state.episode?.providers != nil ? .init(uniqueElements: state.episode!.providers) : nil
            self.selectedProvider = state.selectedProvider
            self.sources = state.sources.value
            self.selectedSource = state.selectedSource
        }
    }

    @ViewBuilder
    var settingsSidebar: some View {
        WithViewStore(
            store.scope(
                state: SettingsSidebarViewState.init
            )
        ) { viewState in
            Group {
                if viewState.isLoading {
                    VStack {
                        ProgressView()
                            .colorInvert()
                            .brightness(1)
                            .scaleEffect(1.25)
                            .frame(width: 32, height: 32, alignment: .center)

                        Text("Loading")
                            .font(.body.bold())
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView(
                        .vertical,
                        showsIndicators: false
                    ) {
                        if let item = viewState.selectedSetting {
                            switch item {
                            case .provider:
                                listsSettings(
                                    viewState.state.selectedProvider,
                                    viewState.selectableProviders
                                ) { id in
                                    viewState.send(.selectProvider(id, saveProgress: true))
                                }
                            case .quality:
                                listsSettings(
                                    viewState.state.selectedSource,
                                    viewState.state.selectableQualities
                                ) { id in
                                    viewState.send(.selectSource(id, saveProgress: true))
                                }
                            case .language:
                                listsSettings(
                                    viewState.state.selectedProvider,
                                    viewState.state.selectableAudio
                                ) { id in
                                    viewState.send(.selectProvider(id, saveProgress: true))
                                }
                            }
                        } else {
                            VStack(alignment: .leading) {
                                createSettingsRow(
                                    "Provider",
                                    viewState.provider?.description ?? "Loading",
                                    viewState.selectableProviders.count
                                ) {
                                    viewState.send(.selectSidebarSettings(.provider))
                                }

                                createSettingsRow(
                                    "Quality",
                                    viewState.quality?.description ?? "Loading",
                                    viewState.selectableQualities?.count ?? 0
                                ) {
                                    viewState.send(.selectSidebarSettings(.quality))
                                }

                                createSettingsRow(
                                    "Audio",
                                    viewState.audio?.description ?? "Loading",
                                    viewState.selectableAudio?.count ?? 0
                                ) {
                                    viewState.send(.selectSidebarSettings(.language))
                                }
                            }
                        }
                    }
                }
            }
        }
        .foregroundColor(Color.white)
        .frame(
            maxWidth: .infinity,
            maxHeight: .infinity
        )
    }

    @ViewBuilder
    private func listsSettings<I: Identifiable>(
        _ selected: I.ID? = nil,
        _ items: IdentifiedArrayOf<I>? = nil,
        _ selectedItem: ((I.ID) -> Void)? = nil
    ) -> some View where I: CustomStringConvertible {
        if let items = items {
            VStack {
                ForEach(items) { item in
                    Text(item.description)
                        .font(.callout.bold())
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .onTapGesture {
                            selectedItem?(item.id)
                        }
                        .background(item.id == selected ? Color.red : Color.clear)
                        .cornerRadius(12)
                }
            }
            .transition(
                .move(edge: .trailing)
                .combined(with: .opacity)
            )
            .frame(
                maxWidth: .infinity,
                maxHeight: .infinity
            )
            .highPriorityGesture(
                DragGesture()
                    .onEnded { value in
                        // Drag right
                        if value.startLocation.x < value.location.x {
                            ViewStore(store.stateless)
                                .send(.selectSidebarSettings(nil))
                        }
                    }
            )
        }
    }

    @ViewBuilder
    private func createSettingsRow(
        _ text: String,
        _ selected: String? = nil,
        _ count: Int = 0,
        _ tapped: (() -> Void)? = nil
    ) -> some View {
        HStack {
            Text(text)
                .font(.callout.bold())

            Spacer()

            if let selected = selected {
                Text(selected)
                    .font(.footnote.bold())
                if count > 1 {
                    Image(systemName: "chevron.compact.right")
                }
            }
        }
        .foregroundColor(Color.white)
        .frame(height: 38)
        .padding(12)
        .background(Color.gray.opacity(0.08))
        .cornerRadius(38 / 4)
        .onTapGesture {
            tapped?()
        }
        .disabled(count <= 1)
    }
}

// MARK: Player Controls

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
