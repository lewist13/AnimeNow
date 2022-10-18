//
//  HomeView.swift
//  Anime Now!
//
//  Created by ErrorErrorError on 9/4/22.
//  Copyright © 2022. All rights reserved.
//

import SwiftUI
import ComposableArchitecture
import SwiftUINavigation
import Kingfisher

struct HomeView: View {
    let store: Store<HomeCore.State, HomeCore.Action>

    var body: some View {
        WithViewStore(store.scope(state: \.isLoading)) { viewStore in
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 24) {
                    animeHeroItems(
                        isLoading: viewStore.state,
                        store: store.scope(
                            state: \.topTrendingAnime
                        )
                    )

                    resumeWatchingEpisodes(
                        store: store.scope(
                            state: \.resumeWatching
                        )
                    )

                    animeItems(
                        title: "Last Watched",
                        isLoading: viewStore.state,
                        store: store.scope(
                            state: \.lastWatchedAnime
                        )
                    )

                    animeItems(
                        title: "Upcoming",
                        isLoading: viewStore.state,
                        store: store.scope(
                            state: \.topUpcomingAnime
                        )
                    )

                    animeItems(
                        title: "Highest Rated",
                        isLoading: viewStore.state,
                        store: store.scope(
                            state: \.highestRatedAnime
                        )
                    )

                    animeItems(
                        title: "Most Popular",
                        isLoading: viewStore.state,
                        store: store.scope(
                            state: \.mostPopularAnime
                        )
                    )
                }
                .placeholder(
                    active: viewStore.state,
                    duration:  2.0
                )
                .animation(.easeInOut(duration: 0.5), value: viewStore.state)
            }
            .disabled(viewStore.state)
            .onAppear {
                viewStore.send(.onAppear)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .ignoresSafeArea()
    }
}

extension HomeView {
    @ViewBuilder
    var topHeaderView: some View {
        Text("Anime Now!")
            .font(.largeTitle.bold())
            .frame(maxWidth: .infinity, alignment: .center)
            .padding()
    }
}

extension HomeView {
    @ViewBuilder
    func animeHero(
        _ anime: Anime
    ) -> some View {
        ZStack(alignment: .bottomLeading) {
            KFImage(
                (DeviceUtil.isPhone ? anime.posterImage.largest : anime.coverImage.largest ?? anime.posterImage.largest)?.link
            )
                .fade(duration: 0.5)
                .resizable()
                .contentShape(Rectangle())
                .clipped()
                .overlay(
                    LinearGradient(
                        colors: [
                            Color.black.opacity(0.3),
                            Color.clear,
                            Color.black.opacity(0.75)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )

            VStack(alignment: .leading, spacing: 4) {
                Text(anime.title)
                    .font(.title.weight(.bold))
                    .lineLimit(2)

                Text(anime.description)
                    .font(.callout)
                    .lineLimit(3)
            }
            .foregroundColor(.white)
            .multilineTextAlignment(.leading)
            .padding()
            .padding(.bottom, 24)
        }
    }
}

// MARK: Anime Hero Items

extension HomeView {
    @ViewBuilder
    func animeHeroItems(
        isLoading: Bool,
        store: Store<HomeCore.LoadableAnime, HomeCore.Action>
    ) -> some View {
        Group {
            if isLoading {
                animeHero(.placeholder)
            } else {
                WithViewStore(store) { viewStore in
                    if let animes = viewStore.state.value,
                       animes.count > 0 {
                        SnapCarousel(
                            items: animes
                        ) { anime in
                            animeHero(anime)
                                .onTapGesture {
                                    viewStore.send(.animeTapped(anime))
                                }
                        }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity)
        .aspectRatio(DeviceUtil.isPhone ? 5/7 : 8/3, contentMode: .fill)
    }
}

// MARK: - Animes View

extension HomeView {
    @ViewBuilder
    func animeItems(
        title: String,
        isLoading: Bool,
        store: Store<HomeCore.LoadableAnime, HomeCore.Action>
    ) -> some View {
        WithViewStore(store) { viewStore in
            if isLoading || viewStore.state.value != nil && viewStore.state.value!.count > 0 {
                VStack(alignment: .leading) {
                    headerText(title)

                    ScrollView(.horizontal, showsIndicators: false) {
                        LazyHStack(alignment: .center, spacing: 12) {
                            if case let .success(animes) = viewStore.state, !isLoading {
                                ForEach(animes) { anime in
                                    AnimeItemView(
                                        anime: anime
                                    )
                                    .onTapGesture {
                                        viewStore.send(.animeTapped(anime))
                                    }
                                }
                            } else {
                                ForEach(0...2, id: \.self) { _ in
                                    AnimeItemView(
                                        anime: .placeholder
                                    )
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                    .frame(height: DeviceUtil.isPhone ? 200 : 275)
                }
            }
        }
    }

    @ViewBuilder
    var failedToFetchAnimesView: some View {
        VStack(alignment: .center) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 24))
                .foregroundColor(.red)
            Text("There seems to be an error fetching shows.")
                .foregroundColor(.red)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Episodes View

extension HomeView {
    @ViewBuilder
    func resumeWatchingEpisodes(
        store: Store<HomeCore.LoadableEpisodes, HomeCore.Action>
    ) -> some View {
        WithViewStore(store) { viewStore in
            if let animeEpisodesInfo = viewStore.state.value,
               animeEpisodesInfo.count > 0 {
                VStack(alignment: .leading) {
                    headerText("Resume Watching")

                    ScrollView(.horizontal, showsIndicators: false) {
                        LazyHStack(alignment: .center) {
                            ForEach(animeEpisodesInfo, id: \.id) { animeEpisodeInfo in
                                ThumbnailItemBigView(
                                    type:
                                        animeEpisodeInfo.episodeInfo.isMovie ?
                                        .movie(
                                            image: animeEpisodeInfo.episodeInfo.cover?.link,
                                            name: animeEpisodeInfo.episodeInfo.title,
                                            progress: animeEpisodeInfo.episodeInfo.progress
                                        ) :
                                        .episode(
                                            image: animeEpisodeInfo.episodeInfo.cover?.link,
                                            name: animeEpisodeInfo.episodeInfo.title,
                                            animeName: animeEpisodeInfo.anime.title,
                                            number: Int(animeEpisodeInfo.episodeInfo.number),
                                            progress: animeEpisodeInfo.episodeInfo.progress
                                        ),
                                    progressSize: 6
                                )
                                .frame(height: DeviceUtil.isPhone ? 150 : 225)
                                .onTapGesture {
                                    viewStore.send(.resumeWatchingTapped(animeEpisodeInfo))
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                }
            }
        }
    }
}

// MARK: - Misc View Helpers

extension HomeView {
    @ViewBuilder
    func headerText(_ title: String) -> some View {
        Text(title)
            .font(DeviceUtil.isPhone ? .headline.bold() : .title2.bold())
            .foregroundColor(.white)
            .padding(.horizontal)
            .opacity(0.9)
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView(
            store: .init(
                initialState: .init(),
                reducer: HomeCore.reducer,
                environment: .init(
                    animeClient: .mock,
                    mainQueue: .main.eraseToAnyScheduler(),
                    mainRunLoop: .main.eraseToAnyScheduler(),
                    repositoryClient: RepositoryClientMock.shared
                )
            )
        )
        .preferredColorScheme(.dark)
    }
}
