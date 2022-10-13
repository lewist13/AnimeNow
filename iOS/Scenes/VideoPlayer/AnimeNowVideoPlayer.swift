//
//  AnimeNowVideoPlayer.swift
//  Anime Now!
//
//  Created Erik Bautista on 10/1/22.
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
        .prefersHomeIndicatorAutoHidden(true)
        .supportedOrientation(.landscape)
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

// MARK: Status Overlay

extension AnimeNowVideoPlayer {
    private struct VideoStatusViewState: Equatable {
        let status: AnimeNowVideoPlayerCore.State.Status?
        let showingPlayerControls: Bool

        init(_ state: AnimeNowVideoPlayerCore.State) {
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

extension AnimeNowVideoPlayer {
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
                    actionButton
                    if showPlayerOverlay.state {
                        VStack(spacing: 0) {
                            videoInfoWithActions
                            bottomPlayerItems
                        }
                        .transition(.move(edge: .bottom).combined(with: .opacity))
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
    var actionButton: some View {
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
                value: viewState.canShowButton
            )
        }
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
// MARK: Top Player Items

extension AnimeNowVideoPlayer {
    @ViewBuilder
    var topPlayerItems: some View {
        HStack {
            closeButton
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .transition(.move(edge: .top).combined(with: .opacity))
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
            .contentShape(Rectangle())
            .frame(width: 30, height: 30)
            .onTapGesture {
                ViewStore(store.stateless).send(.closeButtonTapped)
            }
    }
}

// MARK: Anime Info + Player Options

extension AnimeNowVideoPlayer {
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

extension AnimeNowVideoPlayer {
    private struct AnimeInfoViewState: Equatable {
        let title: String
        let header: String?
        let isMovie: Bool

        init(_ state: AnimeNowVideoPlayerCore.State) {
            let isMovie = state.anime.format == .movie
            self.isMovie = isMovie
            self.title = isMovie ? state.anime.title : (state.episode?.name ?? "Loading...")
            self.header = !isMovie ? "E\(state.selectedEpisode) \u{2022} \(state.anime.title)" : nil
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

extension AnimeNowVideoPlayer {
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
}

// MARK: Bottom Player Items

extension AnimeNowVideoPlayer {
    private struct ProgressViewState: Equatable {
        let progress: Double
        let duration: Double
        let buffered: Double

        var canShow: Bool {
            duration > 0.0
        }

        var progressWithDuration: Double? {
            if duration > 0.0 {
                return progress * duration
            }
            return nil
        }

        init(_ state: AnimeNowVideoPlayerCore.State) {
            self.duration = state.playerDuration
            self.progress = state.playerProgress
            self.buffered = state.playerBuffered
        }
    }

    @ViewBuilder
    var bottomPlayerItems: some View {
        WithViewStore(
            store.scope(
                state: ProgressViewState.init
            )
        ) { viewState in
            VStack(spacing: 0) {
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
                .frame(height: 24)

                HStack(spacing: 4) {
                    Text(
                        viewState.progressWithDuration?.timeFormatted ?? "--:--"
                    )
                    Text("/")
                    Text(
                        viewState.canShow ? viewState.duration.timeFormatted : "--:--"
                    )
                    Spacer()
                }
                .foregroundColor(.white)
                .font(.footnote.bold().monospacedDigit())
            }
            .disabled(!viewState.canShow)
        }
    }
}

// MARK: Sidebar

extension AnimeNowVideoPlayer {
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

extension AnimeNowVideoPlayer {
    private struct EpisodesSidebarViewState: Equatable {
        let episodes: IdentifiedArrayOf<Episode>
        let selectedEpisode: Episode.ID
        let episodesStore: [EpisodeStore]

        init(_ state: AnimeNowVideoPlayerCore.State) {
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

extension AnimeNowVideoPlayer {
    private struct SettingsSidebarViewState: Equatable {
        let selectedSetting: AnimeNowVideoPlayerCore.Sidebar.SettingsState.Section?
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

        init(_ state: AnimeNowVideoPlayerCore.State) {
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

// MARK: Subtitles Sidebar

extension AnimeNowVideoPlayer {
    private struct SubtitlesSidebarViewState: Equatable {
        let subtitles: AVMediaSelectionGroup?
        let selected: AVMediaSelectionOption?

        init(_ state: AnimeNowVideoPlayerCore.State) {
            self.subtitles = state.playerSubtitles
            self.selected = state.playerSelectedSubtitle
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

// MARK: Player Controls

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
            .previewInterfaceOrientation(.landscapeRight)
        } else {
            // Fallback on earlier versions
        }
    }
}
