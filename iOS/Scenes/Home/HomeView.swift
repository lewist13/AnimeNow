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
    @Namespace private var animeDetailNamespace

    var body: some View {
        ZStack {
            ScrollView(.vertical, showsIndicators: false) {
                topHeaderView

                VStack(spacing: 24) {
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
            .onAppear {
                ViewStore(store).send(.onAppear)
            }
            .fullScreenStore(
                store: store.scope(
                    state: \.animeDetail,
                    action: HomeCore.Action.animeDetail
                )
            ) {
                    
            } destination: {
                AnimeDetailView(
                    store: $0,
                    namespace: animeDetailNamespace
                )
            }
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

            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(alignment: .center, spacing: 12) {
                    WithViewStore(store) { viewStore in
                        if case .loading = viewStore.state {
                            loadingAnimePlaceholders
                        } else if case let .success(animes) = viewStore.state {
                            ForEach(animes, id: \.self) { anime in
                                AnimeItemView(
                                    anime: anime,
                                    namespace: animeDetailNamespace
                                )
                                .onTapGesture {
                                    viewStore.send(
                                        .animeTapped(anime),
                                        animation: Animation.spring(
                                            response: 0.3,
                                            dampingFraction: 0.8
                                        )
                                    )
                                }
                            }
                        } else {
                            failedToFetchAnimesView
                        }
                    }
                }
                .padding(.horizontal)
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
                    listClient: .kitsu
                )
            )
        )
        .preferredColorScheme(.dark)
    }
}
