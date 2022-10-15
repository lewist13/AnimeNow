//
//  AnimeDetailView.swift
//  Anime Now!
//
//  Created Erik Bautista on 9/6/22.
//  Copyright © 2022. All rights reserved.
//

import SwiftUI
import ComposableArchitecture
import Kingfisher

struct AnimeDetailView: View {
    let store: Store<AnimeDetailCore.State, AnimeDetailCore.Action>

    var body: some View {
        WithViewStore(store.scope(state: \.loading)) { viewStore in
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 16) {
                    topContainer
                    infoContainer
                    episodesContainer
                }
                .placeholder(active: viewStore.state)
                .transition(.opacity)
                .animation(.easeInOut(duration: 0.3), value: viewStore.state)
            }
            .transition(.move(edge: .bottom).combined(with: .opacity))
            .frame(maxWidth: .infinity)
            .statusBar(hidden: true)
            .ignoresSafeArea(edges: .top)
            .overlay(closeButton)
            .background(
                Color.black
                    .ignoresSafeArea()
            )
            .onAppear {
                viewStore.send(.onAppear)
            }
            .disabled(viewStore.state)
        }
    }
}

// Close button

extension AnimeDetailView {
    @ViewBuilder var closeButton: some View {
        Image(systemName: "xmark")
            .font(.system(size: 14, weight: .black))
            .foregroundColor(Color.white.opacity(0.9))
            .padding(12)
            .background(BlurView(style: .systemThinMaterialDark))
            .clipShape(Circle())
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
            .padding()
            .edgesIgnoringSafeArea(.top)
            .onTapGesture {
                ViewStore(store.stateless)
                    .send(.closeButtonPressed)
            }
    }
}

// MARK: - Top Container

extension AnimeDetailView {

    @ViewBuilder
    var topContainer: some View {
        WithViewStore(
            store.scope(
                state: \.anime
            )
        ) { animeViewStore in
            ZStack(alignment: .bottom) {
                KFImage(animeViewStore.posterImage.largest?.link)
                    .resizable()
                    .overlay(
                        LinearGradient(
                            stops: [
                                .init(
                                    color: .clear,
                                    location: 0.5
                                ),
                                .init(
                                    color: .black,
                                    location: 1.0
                                )
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )

                VStack(alignment: .leading, spacing: 0) {
                    Text(animeViewStore.title)
                        .font(.largeTitle)
                        .bold()
                        .multilineTextAlignment(.leading)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    HStack(alignment: .top, spacing: 4) {
                        ForEach(
                            animeViewStore.categories,
                            id: \.self
                        ) { category in
                            Text(category)
                                .font(.footnote)
                                .bold()
                                .foregroundColor(.white.opacity(0.8))
                            if animeViewStore.categories.last != category {
                                Text("\u{2022}")
                                    .font(.footnote)
                                    .fontWeight(.black)
                                    .foregroundColor(.white.opacity(0.8))
                            }
                        }
                    }

                    HStack {
                        // MARK: Play Button

                        WithViewStore(
                            store.scope(
                                state: \.playButtonState
                            )
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
                            .buttonStyle(PlayButtonStyle(isEnabled: playButtonState.isAvailable))
                            .padding(.vertical, 12)
                            .disabled(!playButtonState.isAvailable)
                        }

                        // MARK: Favorites Button

                        WithViewStore(
                            store.scope(
                                state: \.animeStore.value?.isFavorite
                            )
                        ) { isFavoriteViewStore in
                            Button {
                                isFavoriteViewStore.send(.tappedFavorite)
                            } label: {
                                Image(
                                    systemName: isFavoriteViewStore.state == true ? "heart.fill" : "heart"
                                )
                                    .foregroundColor(
                                        isFavoriteViewStore.state == true ? .red : .white
                                    )
                            }
                            .buttonStyle(BlurredButtonStyle())
                            .background(BlurView(style: .systemThinMaterialDark))
                            .clipShape(Circle())
                        }
                    }
                }
                .frame(
                    maxWidth: .infinity,
                    maxHeight: .infinity,
                    alignment: .bottomLeading
                )
                .padding(.horizontal)
            }
        }
        .aspectRatio(2/3, contentMode: .fill)
    }
}

// MARK: - Info Container

extension AnimeDetailView {

    @ViewBuilder
    var infoContainer: some View {
        WithViewStore(
            store.scope(state: \.anime)
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
                .font(.system(size: 14).bold())
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal)
    }
}


// MARK: Episodes Container

extension AnimeDetailView {

    @ViewBuilder
    var episodesContainer: some View {
        IfLetStore(
            store.scope(
                state: { state -> AnimeDetailCore.LoadableEpisodes? in
                    state.anime.status != .upcoming && state.anime.format != .movie ? state.episodes : nil
                }
            )
        ) { episodesStore in
            WithViewStore(episodesStore) { episodesViewStore in
                if case let .success(episodes) = episodesViewStore.state {
                    if episodes.count > 0 {
                        buildSubHeading(title: "Episodes")
                    }

                    LazyVStack(spacing: 12) {
                        ForEach(episodes, id: \.id) { episode in
                            generateEpisodeItem(episode)
                                .onTapGesture {
                                    episodesViewStore.send(
                                        .selectedEpisode(
                                            episode: episode
                                        )
                                    )
                                }
                        }
                    }
                } else if case .failed = episodesViewStore.state {
                    buildSubHeading(title: "Episodes")

                    ZStack {
                        RoundedRectangle(cornerRadius: 16)
                            .episodeFrame()
                            .foregroundColor(Color.gray.opacity(0.2))
                        
                        Label("Failed to load.", systemImage: "exclamationmark.triangle.fill")
                            .font(.title3.bold())
                            .foregroundColor(Color.red)
                    }
                } else {
                    buildSubHeading(title: "Episodes")
                    generateEpisodeItem(.placeholder)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal)
    }

    @ViewBuilder
    private func generateEpisodeItem(
        _ episode: Episode
    ) -> some View {
        WithViewStore(
            store.scope(
                state: { state -> EpisodeStore? in
                    return state.animeStore.value?.episodeStores.first(where: {
                        $0.number == episode.number
                    })
                }
            )
        ) { progressState in
            ThumbnailItemBigView(
                type: .episode(
                    image: episode.thumbnail.largest?.link,
                    name: episode.name,
                    animeName: nil,
                    number: episode.number,
                    progress: progressState.state?.progress
                ),
                watched: progressState.state?.almostFinished ?? false,
                progressSize: 10
            )
        }
//            .overlay(
//                WithViewStore(
//                    store.scope(state: { $0.moreInfo.contains(episode.id) })
//                ) { visibleViewStore in
//                    Button {
//                        visibleViewStore.send(.moreInfo(id: episode.id), animation: Animation.easeInOut(duration: 0.15))
//                    } label: {
//                        Image(
//                            systemName: visibleViewStore.state ? "chevron.up" : "chevron.down"
//                        )
//                        .font(Font.system(size: 12, weight: .black))
//                        .foregroundColor(Color.white.opacity(0.9))
//                    }
//                    .buttonStyle(BlurredButtonStyle())
//                    .background(BlurView(style: .systemThinMaterialDark))

//                    .clipShape(Circle())
//                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
//                    .padding()
//                }
//            )

//        WithViewStore(
//            store.scope(state: { $0.moreInfo.contains(episode.id) })
//        ) { visibleDescriptionViewStore in
//            if visibleDescriptionViewStore.state {
//                Text(episode.description)
//                    .font(.footnote)
//                    .padding(.horizontal)
//                    .frame(maxWidth: .infinity, alignment: .leading)
//                    .padding(.bottom)
//            }
//        }
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

extension View {
    fileprivate func episodeFrame() -> some View {
        self
            .aspectRatio(16/9, contentMode: .fill)
            .frame(maxWidth: .infinity, alignment: .center)
            .cornerRadius(16)
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

struct AnimeView_Previews: PreviewProvider {
    static var previews: some View {
        AnimeDetailView(
            store: .init(
                initialState: .init(
                    anime: .narutoShippuden,
                    episodes: .success(.init(uniqueElements: Episode.demoEpisodes)),
                    animeStore: .success(
                        .init(
                            id: 0,
                            isFavorite: false,
                            episodeStores: .init()
                        )
                    )
                ),
                reducer: .empty,
                environment: ()
            )
        )
        .preferredColorScheme(.dark)
    }
}
