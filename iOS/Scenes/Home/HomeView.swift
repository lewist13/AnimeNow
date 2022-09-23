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
        ScrollView(.vertical, showsIndicators: false) {
            topHeaderView
            
            LazyVStack(spacing: 24) {
                animeItems(
                    title: "Trending This Week",
                    store: store.scope(
                        state: \.topTrendingAnime
                    )
                )
                
                animeItems(
                    title: "Top Airing Anime",
                    store: store.scope(
                        state: \.topAiringAnime
                    )
                )
                
                animeItems(
                    title: "Top Upcoming Anime",
                    store: store.scope(
                        state: \.topUpcomingAnime
                    )
                )
                
                animeItems(
                    title: "Highest Rated Anime",
                    store: store.scope(
                        state: \.highestRatedAnime
                    )
                )
                
                animeItems(
                    title: "Most Popular Anime",
                    store: store.scope(
                        state: \.mostPopularAnime
                    )
                )
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            ViewStore(store).send(.onAppear)
        }
    }
}

extension HomeView {
    @ViewBuilder
    var topHeaderView: some View {
        Text("Discover")
            .font(.largeTitle.bold())
            .foregroundColor(.white)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal)
            .padding(.vertical, 8)
    }
}

// MARK: - Animes View

extension HomeView {
    @ViewBuilder
    func animeItems(
        title: String,
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
                            if viewStore.state.isLoading {
                                loadingAnimePlaceholders
                            } else if case let .success(animes) = viewStore.state {
                                ForEach(animes, id: \.self) { anime in
                                    AnimeItemView(
                                        anime: anime
                                    )
                                    .onTapGesture {
                                        viewStore.send(
                                            .animeTapped(
                                                anime
                                            )
                                        )
                                    }
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                }
            }
            .frame(height: 200)
        }
    }

    @ViewBuilder
    var loadingAnimePlaceholders: some View {
        ForEach(0...2, id: \.self) { _ in
            Rectangle()
                .foregroundColor(Color.gray.opacity(0.2))
                .shimmering()
                .cornerRadius(12)
                .aspectRatio(2/3, contentMode: .fit)
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
    func currentlyWatchingEpisodes(
        store: Store<[Episode], HomeCore.Action>
    ) -> some View {
        VStack(alignment: .leading) {
            headerText("Currently Watching")

            WithViewStore(store) { viewStore in
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(alignment: .top) {
                    }
                    .padding(.horizontal)
                }
                .frame(height: 150)
            }
        }
    }
}

// MARK: - Misc View Helpers

extension HomeView {
    @ViewBuilder
    func headerText(_ title: String) -> some View {
        Text(title)
            .font(.subheadline)
            .bold()
            .padding(.horizontal)
            .foregroundColor(.white.opacity(0.9))
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
                    mainRunLoop: .main.eraseToAnyScheduler()
                )
            )
        )
        .preferredColorScheme(.dark)
    }
}
