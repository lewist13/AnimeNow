//
//  AnimeDetailView.swift
//  Anime Now!
//
//  Created by ErrorErrorError on 9/6/22.
//  Copyright © 2022. All rights reserved.
//

import SwiftUI
import Kingfisher
import ComposableArchitecture

struct AnimeDetailView: View {
    let store: StoreOf<AnimeDetailReducer>

    var body: some View {
        WithViewStore(
            store,
            observe: \.isLoading
        ) { viewStore in
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 16) {
                    topContainer
                    infoContainer
                    episodesContainer
                    Spacer(minLength: 24)
                }
                .placeholder(active: viewStore.state)
                .transition(.opacity)
                .animation(.easeInOut(duration: 0.3), value: viewStore.state)
            }
            .disabled(viewStore.state)
            .onAppear {
                viewStore.send(.onAppear)
            }
        }
        .transition(.move(edge: .bottom).combined(with: .opacity))
        .frame(maxWidth: .infinity)
        .overlay(closeButton)
        #if os(iOS)
        .ignoresSafeArea(edges: .top)
        .statusBarHidden()
        #endif
        .background(Color.black.ignoresSafeArea())
    }
}

// Close button

extension AnimeDetailView {
    @ViewBuilder var closeButton: some View {
        Button {
            ViewStore(store.stateless)
                .send(.closeButtonPressed)
        } label: {
            Image(systemName: DeviceUtil.isMac ? "chevron.backward" : "xmark")
                .font(.system(size: 14, weight: .black))
                .foregroundColor(Color.white.opacity(0.9))
                .padding(12)
                .background(Color(white: 0.2))
                .clipShape(Circle())
                .padding()
        }
        .buttonStyle(.plain)
        .frame(
            maxWidth: .infinity,
            maxHeight: .infinity,
            alignment: DeviceUtil.isMac ? .topLeading : .topTrailing
        )
    }
}

// MARK: - Top Container

extension AnimeDetailView {

    @ViewBuilder
    var topContainer: some View {
        WithViewStore(
            store,
            observe: { $0.isLoading ? .placeholder : $0.anime.value ?? .placeholder }
        ) { animeViewStore in
            ZStack {
                GeometryReader { reader in
                    FillAspectImage(
                        url: (DeviceUtil.isPhone ? animeViewStore.posterImage.largest : animeViewStore.coverImage.largest ?? animeViewStore.posterImage.largest)?.link
                    )
                    .frame(
                        width: reader.size.width,
                        height: reader.size.height + (reader.frame(in: .global).minY > 0 ? reader.frame(in: .global).minY : 0),
                        alignment: .center
                    )
                    .contentShape(Rectangle())
                    .clipped()
                    .offset(y: reader.frame(in: .global).minY <= 0 ? 0 : -reader.frame(in: .global).minY)
                }

                VStack(alignment: .leading, spacing: 8) {
                    VStack {
                        Text(animeViewStore.title)
                            .font(.largeTitle)
                            .bold()
                            .multilineTextAlignment(.leading)
                            .foregroundColor(.white)
                            .lineLimit(2)
                            .frame(
                                maxWidth: .infinity,
                                alignment: .leading
                            )

                        HStack(alignment: .top, spacing: 4) {
                            ForEach(
                                animeViewStore.categories,
                                id: \.self
                            ) { category in
                                Text(category)
                                    .font(.footnote)
                                    .bold()
                                    .foregroundColor(.white.opacity(0.8))
                                createDot(animeViewStore.categories, category)
                            }
                            Spacer()
                        }
                    }

                    HStack {
                        // MARK: Play Button

                        WithViewStore(
                            store,
                            observe: { $0.playButtonState }
                        ) { playButtonState in
                            Button {
                                animeViewStore.send(.playResumeButtonClicked)
                            } label: {
                                switch playButtonState.state {
                                case .unavailable, .comingSoon:
                                    Text(playButtonState.stringValue)
                                case .playFromBeginning, .playNextEpisode, .resumeEpisode:
                                    HStack {
                                        Image(systemName: "play.fill")
                                        Text(playButtonState.stringValue)
                                    }
                                }
                            }
                            .buttonStyle(PlayButtonStyle(
                                isEnabled: playButtonState.isAvailable)
                            )
                            .clipShape(Capsule())
                            .disabled(!playButtonState.isAvailable)
                        }

                        Spacer()

                        WithViewStore(
                            store,
                            observe: \.isLoading
                        ) { viewState in
                            Button {
                                viewState.send(.tappedCollectionList)
                            } label: {
                                Image(systemName: "plus")
                                    .font(.body.bold())
                                    .foregroundColor(.white)
                                    .padding()
                                    .background(Color(white: 0.15))
                                    .clipShape(Circle())
                            }
                            .buttonStyle(.plain)
                            .contentShape(Rectangle())
                        }

                        WithViewStore(
                            store,
                            observe: { $0.isLoading ? nil : $0.animeStore.value?.isFavorite }
                        ) { isFavoriteViewStore in
                            Button {
                                isFavoriteViewStore.send(.tappedFavorite)
                            } label: {
                                Image(systemName: "heart.fill")
                                    .font(.body.bold())
                                    .foregroundColor(.white)
                                    .padding()
                                    .background(isFavoriteViewStore.state == true ? Color.red : Color(white: 0.15))
                                    .clipShape(Circle())
                            }
                            .buttonStyle(.plain)
                            .contentShape(Rectangle())
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.vertical)
                .background(
                    LinearGradient(
                        stops: [
                            .init(
                                color: .clear,
                                location: 0.0
                            ),
                            .init(
                                color: .black.opacity(0.85),
                                location: 1.0
                            )
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(
                    maxWidth: .infinity,
                    maxHeight: .infinity,
                    alignment: .bottomLeading
                )
            }
        }
        .aspectRatio(DeviceUtil.isPhone ? 2/3 : DeviceUtil.isPad ? 7/3 : 9/3, contentMode: .fit)
        .frame(maxWidth: .infinity)
    }

    @ViewBuilder
    private func createDot(_ items: [String], _ current: String) -> some View {
        if items.last != current {
            Text("\u{2022}")
                .font(.footnote)
                .fontWeight(.black)
                .foregroundColor(.white.opacity(0.8))
        } else {
            EmptyView()
        }
    }
}

// MARK: - Info Container

extension AnimeDetailView {

    @ViewBuilder
    var infoContainer: some View {
        WithViewStore(
            store,
            observe: { $0.isLoading ? .placeholder : $0.anime.value ?? .placeholder }
        ) { anime in
            VStack(alignment: .leading, spacing: 12) {

                // MARK: Description Info

                Text(anime.description)
                    .font(.body)
                    .foregroundColor(.white.opacity(0.85))
                    .lineLimit(3)
                    .frame(maxWidth: .infinity, alignment: .leading)

                // Bubbles info

                HStack {
                    if let rating = anime.avgRating {
                        ChipView(
                            text: "\(ceil((rating * 5) / 0.5) * 0.5)"
                        ) {
                            Image(systemName: "star.fill")
                                .foregroundColor(.yellow)
                        }
                    }

                    if let year = anime.releaseYear {
                        ChipView(text: "\(year)")
                    }

                    ChipView(text: anime.format.rawValue)
                }
                .foregroundColor(.white)
                .font(.system(size: 14).bold())
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal)
    }
}

// MARK: Episodes Container

extension AnimeDetailView {

    private struct EpisodesViewState: Equatable {
        let episodes: [Episode]?
        let compact: Bool

        init(_ state: AnimeDetailReducer.State) {
            if state.isLoading {
                self.episodes = Episode.placeholders(8)
            } else {
                self.episodes = state.episodes.value
            }
            self.compact = state.compactEpisodes
        }
    }

    @ViewBuilder
    var episodesContainer: some View {
            WithViewStore(
                store,
                observe: EpisodesViewState.init
            ) { viewState in
                if let episodes = viewState.episodes {
                    HStack(alignment: .center) {
                        buildSubHeading(title: "Episodes")

                        Spacer()

                        if DeviceUtil.isPhone {
                            Image(viewState.compact ? "rectangle.inset.filled" : "rectangle.grid.1x2.fill")
                                .font(.body.bold())
                                .foregroundColor(.white)
                                .onTapGesture {
                                    viewState.send(
                                        .toggleCompactEpisodes,
                                        animation: .easeInOut(duration: 0.25)
                                    )
                                }
                        }
                    }
                    .padding(.horizontal)

                    if DeviceUtil.isPhone {
                        LazyVStack(spacing: 12) {
                            ForEach(episodes, id: \.id) { episode in
                                generateEpisodeItem(
                                    episode,
                                    compact: viewState.compact
                                )
                            }
                        }
                        .padding(.horizontal)
                    } else {
                        ScrollView(.horizontal, showsIndicators: false) {
                            LazyHStack {
                                ForEach(episodes, id: \.id) { episode in
                                    generateEpisodeItem(
                                        episode,
                                        compact: false
                                    )
                                }
                            }
                            .padding(.horizontal)
                        }
                        .frame(height: 200)
                    }
                }
            }
            .frame(maxWidth: .infinity)
    }

    struct EpisodeDownloadingViewState: Equatable {
        var episodeStore: EpisodeStore?
        var downloadStatus: DownloaderClient.Status?

        init(_ state: AnimeDetailReducer.State, _ episodeNumber: Int) {
            self.episodeStore = state.animeStore.value?.episodes.first(where: { $0.number == episodeNumber })
            self.downloadStatus = state.episodesStatus[id: episodeNumber]?.status
        }
    }

    @ViewBuilder
    private func generateEpisodeItem(
        _ episode: Episode,
        compact: Bool
    ) -> some View {
        WithViewStore(
            store,
            observe: { state in
                EpisodeDownloadingViewState(state, episode.number)
            }
        ) { viewState in
            Group {
                if compact {
                    ThumbnailItemCompactView(
                        episode: episode,
                        progress: viewState.episodeStore?.progress,
                        downloadStatus: .init(
                            state: viewState.downloadStatus,
                            callback: { action in
                                switch action {
                                case .download:
                                    viewState.send(.downloadEpisode(episode))
                                case .cancel:
                                    viewState.send(.cancelDownload(episode.number))
                                case .retry:
                                    viewState.send(.retryDownload(episode.number))
                                }
                            }
                        )
                    )
                    .frame(height: 85)
                } else {
                    ThumbnailItemBigView(
                        type: .episode(
                            image: episode.thumbnail?.link,
                            name: episode.title,
                            animeName: nil,
                            number: episode.number,
                            progress: viewState.episodeStore?.progress
                        ),
                        isFiller: episode.isFiller,
                        progressSize: 10,
                        downloadStatus: .init(
                            state: viewState.downloadStatus,
                            callback: { action in
                                switch action {
                                case .download:
                                    viewState.send(.downloadEpisode(episode))
                                case .cancel:
                                    viewState.send(.cancelDownload(episode.number))
                                case .retry:
                                    viewState.send(.retryDownload(episode.number))
                                }
                            }
                        )
                    )
                }
            }
            .animation(.easeInOut(duration: 0.2), value: viewState.episodeStore?.progress)
            .onTapGesture {
                viewState.send(
                    .selectedEpisode(
                        episode.id
                    )
                )
            }
            .contextMenu {
                if (viewState.episodeStore?.almostFinished ?? false) {
                    Button {
                        viewState.send(
                            .markEpisodeAsUnwatched(episode.number),
                            animation: .easeInOut(duration: 0.15)
                        )
                    } label: {
                        Text("Unwatch")
                    }
                } else {
                    Button {
                        viewState.send(
                            .markEpisodeAsWatched(episode.id),
                            animation: .easeInOut(duration: 0.15)
                        )
                    } label: {
                        Text("Mark as Watched")
                    }
                }

                if case .downloaded = viewState.downloadStatus {
                    Button {
                        viewState.send(.removeDownload(episode.number))
                    } label: {
                        Text("Remove Download")
                    }
                } else if viewState.downloadStatus?.canCancelDownload == true {
                    Button {
                        viewState.send(.cancelDownload(episode.number))
                    } label: {
                        Text("Cancel Download")
                    }
                } else if case .failed = viewState.downloadStatus {
                    Button {
                        viewState.send(.retryDownload(episode.number))
                    } label: {
                        Text("Retry Download")
                    }
                }
            }
        }
    }
}

extension AnimeDetailView {
    @ViewBuilder
    func buildSubHeading(title: String) -> some View {
        Text(title)
            .font(.title2.bold())
            .foregroundColor(.white)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

extension AnimeDetailView {
    struct PlayButtonStyle: ButtonStyle {
        let isEnabled: Bool

        func makeBody(configuration: Configuration) -> some View {
            configuration.label
                .font(.system(size: 13).weight(.heavy))
                .padding()
                .background(isEnabled ? Color.white : Color.init(.sRGB, white: 0.15, opacity: 1.0))
                .foregroundColor(isEnabled ? .black : .white)
                .clipShape(Capsule())
                .scaleEffect(configuration.isPressed ? 0.9 : 1)
                .animation(.easeOut(duration: 0.2), value: configuration.isPressed)
        }
    }
}

struct AnimeDetailView_Previews: PreviewProvider {
    static var previews: some View {
        AnimeDetailView(
            store: .init(
                initialState: .init(
                    anime: Anime.narutoShippuden,
                    episodes: .success(Episode.demoEpisodes),
                    animeStore: .success(
                        .init()
                    )
                ),
                reducer: AnimeDetailReducer()
            )
        )
        .frame(width: 800, height: 600)
    }
}
