//
//  AnimePlayerView+iOS.swift
//  Anime Now! (iOS)
//
//  Created by ErrorErrorError on 10/16/22.
//

import SwiftUI
import AVFoundation
import ComposableArchitecture

// MARK: Player Controls Overlay

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
                .padding(safeAreaInsetPadding(proxy))
                .ignoresSafeArea()
                .background(
                    Color.black.opacity(0.5)
                        .ignoresSafeArea()
                        .allowsHitTesting(false)
                        .opacity(showPlayerOverlay.state ? 1 : 0)
                )
            }
        }
        .overlay(statusOverlay)
        .overlay(sidebarOverlay)
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

// MARK: Player Status

extension AnimePlayerView {
    private struct VideoStatusViewState: Equatable {
        let status: AnimePlayerReducer.State.Status?
        let showingPlayerControls: Bool
        let loaded: Bool

        init(_ state: AnimePlayerReducer.State) {
            self.status = state.status
            self.showingPlayerControls = state.showPlayerOverlay
            self.loaded = state.playerDuration != 0
        }

        var canShowSkipSeek: Bool {
            switch status {
            case .error:
                return false
            default:
                return showingPlayerControls
            }
        }
    }

    @ViewBuilder
    var statusOverlay: some View {
        WithViewStore(
            store.scope(state: VideoStatusViewState.init)
        ) { viewState in
            HStack(spacing: 24) {
                if viewState.canShowSkipSeek {
                    Image(systemName: "gobackward.15")
                        .frame(width: 48, height: 48)
                        .foregroundColor(viewState.state.loaded ? .white : .gray)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            viewState.send(.backwardsTapped)
                        }
                        .disabled(!viewState.state.loaded)
                }

                switch viewState.status {
                case .some(.loading):
                    loadingView
                case .some(.playing), .some(.paused):
                        if viewState.showingPlayerControls {
                            Image(systemName: viewState.status == .playing ? "pause.fill" : "play.fill")
                                .font(.title.bold())
                                .frame(width: 48, height: 48)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    viewState.send(.togglePlayback)
                                }
                                .foregroundColor(Color.white)
                        }
                case .some(.replay):
                    Image(systemName: "arrow.counterclockwise")
                        .frame(width: 48, height: 48)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            viewState.send(.replayTapped)
                        }
                        .foregroundColor(Color.white)
                default:
                    EmptyView()
                }

                if viewState.canShowSkipSeek {
                    Image(systemName: "goforward.15")
                        .frame(width: 48, height: 48)
                        .contentShape(Rectangle())
                        .foregroundColor(
                            viewState.state.loaded && viewState.status != .replay ? .white : .gray
                        )
                        .onTapGesture {
                            viewState.send(.forwardsTapped)
                        }
                        .disabled(!viewState.state.loaded || viewState.status == .replay)
                }
            }
            .font(.title)
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
            airplayButton
            subtitlesButton
            episodesButton
            settingsButton
        }
        .frame(maxWidth: .infinity)
        .transition(.move(edge: .top).combined(with: .opacity))
    }
}

// MARK: Sidebar overlay

extension AnimePlayerView {
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
                            case .subtitles:
                                subtitlesSidebar
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
                    .gesture(
                        DragGesture()
                            .onEnded { value in
                                // Drag right
                                if value.startLocation.x < value.location.x {
                                    ViewStore(store.stateless).send(.closeSidebar)
                                }
                            }
                    )
                } else {
                    EmptyView()
                }
            }
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

extension AnimePlayerView {
    private struct EpisodesSidebarViewState: Equatable {
        let loading: Bool
        let episodes: [AnyEpisodeRepresentable]
        let selectedEpisode: Episode.ID
        let episodesStore: [EpisodeStore]

        init(_ state: AnimePlayerReducer.State) {
            self.loading = !state.episodes.finished
            self.episodes = state.episodes.value ?? []
            self.selectedEpisode = state.selectedEpisode
            self.episodesStore = state.animeStore.value?.episodeStores ?? .init()
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
                    if viewStore.state.loading {
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
                    } else if viewStore.state.episodes.count > 0 {
                        LazyVStack {
                            ForEach(viewStore.episodes) { episode in
                                ThumbnailItemCompactView(
                                    episode: episode,
                                    progress: viewStore.episodesStore.first(where: { $0.number == episode.id })?.progress
                                )
                                .overlay(
                                    selectedEpisodeOverlay(episode.id == viewStore.selectedEpisode)
                                )
                                .onTapGesture {
                                    if viewStore.selectedEpisode != episode.id {
                                        viewStore.send(.selectEpisode(episode.id))
                                    }
                                }
                                .id(episode.id)
                                .frame(height: 76)
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
    }

    @ViewBuilder
    private func selectedEpisodeOverlay(_ selected: Bool) -> some View {
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

extension AnimePlayerView {
    private struct SettingsSidebarViewState: Equatable {
        let selectedSetting: AnimePlayerReducer.Sidebar.SettingsState.Section?
        let selectedProvider: Provider.ID?
        let selectedSource: Source.ID?
        let isLoading: Bool

        private let providers: [Provider]?
        private let sources: [Source]?

        var provider: Provider? {
            if let selectedProvider = selectedProvider {
                return providers?[id: selectedProvider]
            }
            return nil
        }

        var selectableProviders: [Provider] {
            if let providers = providers {
                var returnVal = [Provider]()

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

        var selectableQualities: [IdentifiedQuality]? {
            if let sources = sources {
                return sources.map(IdentifiedQuality.init)
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
            let id: Provider.ID
            let language: String

            init(_ provider: Provider) {
                self.id = provider.id
                self.language = (provider.dub ?? false) ? "English" : "Japanese"
            }

            var description: String {
                language
            }
        }

        var selectableAudio: [IdentifiedAudio]? {
            if let providers = providers, let provider = provider {
                let filtered = providers.filter { $0.description == provider.description }
                return filtered.map(IdentifiedAudio.init)
            }
            return nil
        }

        var audio: IdentifiedAudio? {
            if let provider = provider, let languages = selectableAudio {
                return languages[id: provider.id]
            }
            return nil
        }

        init(_ state: AnimePlayerReducer.State) {
            if case .settings(let item) = state.selectedSidebar {
                self.selectedSetting = item.selectedSection
            } else {
                self.selectedSetting = nil
            }
            self.isLoading = !state.episodes.finished || !state.sources.finished
            self.providers = state.episode?.providers
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
                                    viewState.send(.selectProvider(id))
                                }
                            case .quality:
                                listsSettings(
                                    viewState.state.selectedSource,
                                    viewState.state.selectableQualities
                                ) { id in
                                    viewState.send(.selectSource(id))
                                }
                            case .language:
                                listsSettings(
                                    viewState.state.selectedProvider,
                                    viewState.state.selectableAudio
                                ) { id in
                                    viewState.send(.selectProvider(id))
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
        _ items: [I]? = nil,
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

// MARK: Subtitles Sidebar

extension AnimePlayerView {
    private struct SubtitlesSidebarViewState: Equatable {
        let subtitles: AVMediaSelectionGroup?
        let selected: AVMediaSelectionOption?

        init(_ state: AnimePlayerReducer.State) {
            subtitles = nil
            selected = nil
//            self.subtitles = state.playerSubtitles
//            self.selected = state.playerSelectedSubtitle
        }
    }

    @ViewBuilder
    var subtitlesSidebar: some View {
        ScrollViewReader { proxy in
            ScrollView(
                .vertical,
                showsIndicators: false
            ) {
                WithViewStore(
                    store.scope(
                        state: SubtitlesSidebarViewState.init
                    )
                ) { viewStore in
                    LazyVStack {
                        ForEach(viewStore.subtitles?.options ?? [], id: \.self) { subtitle in
                            Text(subtitle.displayName)
                                .font(.callout.bold())
                                .padding(12)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .onTapGesture {
//                                    selectedItem?(item.id)
                                }
                                .background(subtitle == viewStore.selected ? Color.red : Color.clear)
                                .cornerRadius(12)
                                .id(subtitle.displayName)
                        }
                    }
                    .padding([.bottom])
                }
            }
        }

    }
}

// MARK: Bottom Player Items

extension AnimePlayerView {
    @ViewBuilder
    var bottomPlayerItems: some View {
        seekbarAndDurationView
            .transition(.move(edge: .bottom).combined(with: .opacity))
    }
}

// MARK: Seekbar and Duration Items

extension AnimePlayerView {
    @ViewBuilder
    var seekbarAndDurationView: some View {
        WithViewStore(
            store.scope(
                state: ProgressViewState.init
            )
        ) { viewState in
            HStack(
                spacing: 12
            ) {
                SeekbarView(
                    progress: .init(
                        get: {
                            viewState.progress
                        },
                        set: { progress in
                            viewState.send(.seeking(to: progress))
                        }
                    ),
                    buffered: viewState.state.buffered,
                    padding: 6
                ) {
                    viewState.send($0 ? .startSeeking : .stopSeeking)
                }
                .frame(height: 20)

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
                .font(.footnote.bold().monospacedDigit())
            }
            .disabled(!viewState.canShow)
        }
    }
}
