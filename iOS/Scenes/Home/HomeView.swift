//
//  HomeView.swift
//  Anime Now!
//
//  Created Erik Bautista on 9/4/22.
//  Copyright © 2022. All rights reserved.
//

import SwiftUI
import ComposableArchitecture
import SwiftUINavigation

struct HomeView: View {
    let store: Store<HomeCore.State, HomeCore.Action>

    var body: some View {
        WithViewStore(store.scope(state: \.isLoading)) { viewStore in
            ScrollView(.vertical, showsIndicators: false) {
                topHeaderView

                LazyVStack(spacing: 24) {
                    animeItems(
                        title: "Trending Now",
                        isLoading: viewStore.state,
                        store: store.scope(
                            state: \.topTrendingAnime
                        )
                    )

                    resumeWatchingEpisodes(
                        store: store.scope(state: \.resumeWatching)
                    )

                    animeItems(
                        title: "Top Airing",
                        isLoading: viewStore.state,
                        store: store.scope(
                            state: \.topAiringAnime
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
                .placeholder(active: viewStore.state, duration:  2.0)
                .animation(.easeInOut(duration: 0.5), value: viewStore.state)
            }
            .disabled(viewStore.state)
            .onAppear {
                viewStore.send(.onAppear)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

extension HomeView {
    @ViewBuilder
    var topHeaderView: some View {
        Text("Discover")
            .font(.largeTitle.bold())
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding([.horizontal, .top])
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
        VStack(alignment: .leading) {
            headerText(title)

            WithViewStore(store) { viewStore in
                if case .failed = viewStore.state {
                    failedToFetchAnimesView
                        .padding(.horizontal)
                } else {
                    ScrollView(.horizontal, showsIndicators: false) {
                        LazyHStack(alignment: .center, spacing: 12) {
                            if case let .success(animes) = viewStore.state, !isLoading {
                                ForEach(animes, id: \.self) { anime in
                                    AnimeItemView(
                                        anime: anime
                                    )
                                    .onTapGesture {
                                        viewStore.send(.animeTapped(anime))
                                    }
                                }
                            } else {
                                ForEach(0...2, id: \.self) { _ in
                                    AnimeItemView(anime: .placeholder)
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                }
            }
            .frame(height: 218)
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
    }
}

// MARK: - Episodes View

extension HomeView {
    @ViewBuilder
    func resumeWatchingEpisodes(
        store: Store<HomeCore.LoadableEpisodes, HomeCore.Action>
    ) -> some View {
        WithViewStore(store) { viewStore in
            if case .success(let animeEpisodesInfo) = viewStore.state, animeEpisodesInfo.count > 0 {
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
                                        )
                                )
                                .frame(height: 150)
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
            .font(.title3.bold())
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
