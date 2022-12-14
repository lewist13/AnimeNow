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
            .onVolumeChanged { volume in
                viewStore.send(.playerVolume(volume))
            }
            .onAppear {
                viewStore.send(.onAppear)
            }
            .overlay(subtitlesOverlay)
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
        #if os(iOS)
        .prefersHomeIndicatorAutoHidden(true)
        .supportedOrientation(.landscape)
        .statusBarHidden()
        #endif
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
            observe: \.status
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
            self.canShowButton = state.selectedSidebar == nil && self.action != nil && state.playerDuration > 0.0
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
                        ) {
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
                        ) {
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
        .padding(.vertical, 4)
    }

    @ViewBuilder
    private func actionButtonBase(
        _ image: String,
        _ title: String,
        _ textColor: Color,
        _ background: Color,
        _ action: (() -> Void)? = nil
    ) -> some View {
        Button {
            action?()
        } label: {
            HStack {
                Image(systemName: image)
                Text(title)
            }
            .font(.system(size: 13).weight(.heavy))
            .foregroundColor(textColor)
            .padding(12)
            .background(background)
            .cornerRadius(12)
            .clipShape(Capsule())
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .shadow(color: Color.gray.opacity(0.25), radius: 6)
    }
}

// MARK: Dismiss Button

extension AnimePlayerView {
    @ViewBuilder
    var dismissButton: some View {
        Button {
            ViewStore(store.stateless).send(.closeButtonTapped)
        } label: {
            Image(
                systemName: "chevron.backward"
            )
            .foregroundColor(Color.white)
            .font(.title3.weight(.heavy))
            .frame(width: 42, height: 42, alignment: .center)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
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
                ViewStore(store.stateless).send(.toggleSettings)
            }
    }

    @ViewBuilder
    var subtitlesButton: some View {
        WithViewStore(
            store,
            observe: { ($0.sourcesOptions.value?.subtitles.count ?? 0) > 0}
        ) { viewStore in
            if viewStore.state {
                Image(systemName: "captions.bubble.fill")
                    .foregroundColor(Color.white)
                    .font(.title2)
                    .padding(4)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        viewStore.send(.toggleSubtitles)
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
            store,
            observe: \.nextEpisode
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
            observe: { ($0.episodes.value?.count ?? 0) > 1 }
        ) { viewState in
            if viewState.state {
                Image("play.rectangle.on.rectangle.fill")
                    .foregroundColor(.white)
                    .font(.title2)
                    .padding(4)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        viewState.send(.toggleEpisodes)
                    }
            }
        }
    }
}

// MARK: Subtitles View

extension AnimePlayerView {
    struct SubtitlesTextOverlayState: Equatable {
        let subtitle: URL?
        let progress: Double
        let duration: Double

        init(_ state: AnimePlayerReducer.State) {
            if let subtitles = state.sourcesOptions.value?.subtitles,
               let selected = state.selectedSubtitle,
               let subtitle = subtitles[id: selected] {
                self.subtitle = subtitle.url
            } else {
                self.subtitle = nil
            }
            self.progress = state.playerProgress
            self.duration = state.playerDuration
        }
    }

    @ViewBuilder
    var subtitlesOverlay: some View {
        WithViewStore(
            store,
            observe: SubtitlesTextOverlayState.init
        ) { viewStore in
            SubtitleTextView(
                url: viewStore.subtitle,
                progress: viewStore.progress,
                duration: viewStore.duration
            )
            .frame(
                maxWidth: .infinity,
                maxHeight: .infinity
            )
        }
    }
}

// MARK: Sidebar overlay

extension AnimePlayerView {
    @ViewBuilder
    var sidebarOverlay: some View {
        IfLetStore(
            store.scope(
                state: {
                    $0.selectedSidebar != .episodes ? $0.selectedSidebar : nil
                }
            )
        ) { store in
            WithViewStore(
                store,
                observe: { $0 }
            ) { selectedSidebar in
                VStack {
                    HStack(alignment: .center) {
                        if case .settings(let options) = selectedSidebar.state,
                           let section = options.selectedSection {
                            Image(systemName: "chevron.backward")
                                .font(.body.weight(.heavy))
                                .padding(2)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    selectedSidebar.send(.selectSidebarSettings(nil))
                                }

                            Text("\(section.description)")
                                .foregroundColor(Color.white)
                                .font(.title2)
                                .bold()
                        } else {
                            Text("\(selectedSidebar.description)")
                                .foregroundColor(Color.white)
                                .font(.title2)
                                .bold()
                        }
                        Spacer()
                    }

                    switch selectedSidebar.state {
                    case .episodes:
                        EmptyView()

                    case .settings:
                        settingsSidebar

                    case .subtitles:
                        subtitlesSidebar
                    }
                }
                .frame(
                    maxWidth: .infinity,
                    maxHeight: .infinity
                )
                .aspectRatio(8/9, contentMode: .fit)
                .padding(24)
                .background(
                    Color(white: 0.12)
                        .cornerRadius(16)
                )
            }
            .transition(DeviceUtil.isPhone ? .move(edge: .trailing).combined(with: .opacity) : .identity)
        }
    }
}

// Settings Sidebar

extension AnimePlayerView {
    private struct SettingsViewState: Equatable {
        let selectedSetting: AnimePlayerReducer.Sidebar.SettingsState.Section?
        let videoPreferece: VideoOptionsViewState

        init(_ state: AnimePlayerReducer.State) {
            if case .settings(let item) = state.selectedSidebar {
                self.selectedSetting = item.selectedSection
            } else {
                self.selectedSetting = nil
            }

            videoPreferece = .init(state)
        }
    }
}

// MARK: Settings Sidebar

extension AnimePlayerView {

    @ViewBuilder
    var settingsSidebar: some View {
        WithViewStore(
            store,
            observe: SettingsViewState.init
        ) { viewState in
            ScrollView(
                .vertical,
                showsIndicators: false
            ) {
                if let item = viewState.selectedSetting {
                    switch item {
                    case .provider:
                        SettingsListView(
                            items: viewState.videoPreferece.selectableProviders,
                            selected: viewState.state.videoPreferece.selectedProvider
                        ) { id in
                            viewState.send(.selectProvider(id))
                        }

                    case .quality:
                        SettingsListView(
                            items: viewState.state.videoPreferece.selectableQualities,
                            selected: viewState.state.videoPreferece.selectedSource
                        ) { id in
                            viewState.send(.selectSource(id))
                        }

                    case .audio:
                        SettingsListView(
                            items: viewState.state.videoPreferece.selectableAudio,
                            selected: viewState.state.videoPreferece.selectedProvider
                        ) { id in
                            viewState.send(.selectAudio(id))
                        }
                    }
                } else {
                    VStack(alignment: .leading) {
                        SettingsRowView(
                            name: "Provider",
                            selected: viewState.videoPreferece.provider?.description ?? "Loading",
                            multiSelectionable: viewState.videoPreferece.selectableProviders.count > 1
                        ) {
                            viewState.send(.selectSidebarSettings(.provider))
                        }
                        .disabled(viewState.videoPreferece.selectableProviders.count < 2)

                        SettingsRowView(
                            name: "Quality",
                            selected: viewState.videoPreferece.quality?.description ?? "Loading",
                            multiSelectionable: (viewState.videoPreferece.selectableQualities?.count ?? 0) > 1
                        ) {
                            viewState.send(.selectSidebarSettings(.quality))
                        }
                        .disabled((viewState.videoPreferece.selectableQualities?.count ?? 0) < 2)

                        SettingsRowView(
                            name: "Audio",
                            selected: viewState.videoPreferece.audio?.description ?? "Loading",
                            multiSelectionable: (viewState.videoPreferece.selectableAudio?.count ?? 0) > 1
                        ) {
                            viewState.send(.selectSidebarSettings(.audio))
                        }
                        .disabled((viewState.videoPreferece.selectableAudio?.count ?? 0) < 2)
                    }
                }
            }
            .disabled(viewState.videoPreferece.isLoadingProviders)
        }
        .foregroundColor(Color.white)
        .frame(
            maxWidth: .infinity,
            maxHeight: .infinity
        )
    }
}

// MARK: Subtitles Sidebar

extension AnimePlayerView {
    struct SubtitlesViewState: Equatable {
        let subtitles: [Source.Subtitle]?
        let selected: Source.Subtitle.ID?

        init(_ state: AnimePlayerReducer.State) {
            self.subtitles = state.sourcesOptions.value?.subtitles
            self.selected = state.selectedSubtitle
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
                        state: SubtitlesViewState.init
                    )
                ) { viewStore in
                    LazyVStack {
                        Text("None")
                            .font(.callout.bold())
                            .padding(12)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background((viewStore.selected == nil) ? Color.red : Color.clear)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                viewStore.send(.selectSubtitle(nil))
                            }
                            .cornerRadius(12)

                        ForEach(viewStore.subtitles ?? []) { subtitle in
                            Text(subtitle.lang)
                                .font(.callout.bold())
                                .padding(12)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(
                                    subtitle.id == viewStore.selected ? Color.red : Color.clear
                                )
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    viewStore.send(.selectSubtitle(subtitle.id))
                                }
                                .cornerRadius(12)
                        }
                    }
                    .padding([.bottom])
                }
            }
        }
    }
}

struct VideoPlayerView_Previews: PreviewProvider {
    static var previews: some View {
        if #available(iOS 15.0, macOS 12.0, *) {
            AnimePlayerView(
                store: .init(
                    initialState: .init(
                        anime: Anime.narutoShippuden,
                        episodes: .init(Episode.demoEpisodes.map({ $0.eraseAsRepresentable() })),
                        selectedEpisode: Episode.demoEpisodes.first!.id
                    ),
                    reducer: AnimePlayerReducer()
                )
            )
            .previewInterfaceOrientation(.landscapeLeft)
        } else {
            // Fallback on earlier versions
        }
    }
}
