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
    let store: StoreOf<HomeReducer>

    var body: some View {
        WithViewStore(
            store,
            observe: { $0.isLoading }
        ) { viewStore in
            ScrollView(.vertical, showsIndicators: false) {
                ExtraTopSafeAreaInset()

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
                .animation(
                    .easeInOut(duration: 0.5),
                    value: viewStore.state
                )

                ExtraBottomSafeAreaInset()

                Spacer(minLength: 32)
            }
            .disabled(viewStore.state)
            .onAppear {
                viewStore.send(.onAppear)
            }
        }
        .frame(
            maxWidth: .infinity,
            maxHeight: .infinity
        )
        #if os(iOS)
        .ignoresSafeArea(.container, edges: DeviceUtil.isPhone ? .top : [])
        #endif
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
        ZStack(
            alignment: .bottomLeading
        ) {
            FillAspectImage(
                url: (DeviceUtil.isPhone ? anime.posterImage.largest : anime.coverImage.largest ?? anime.posterImage.largest)?.link
            )
            .overlay(
                LinearGradient(
                    stops: [
                        .init(
                            color: .clear,
                            location: 0.4
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
        store: Store<HomeReducer.LoadableAnime, HomeReducer.Action>
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
        .aspectRatio(DeviceUtil.isPhone ? 5/7 : 9/3, contentMode: .fill)
        .cornerRadius(DeviceUtil.isPhone ? 0 : 32)
        #if os(macOS)
        .padding(.horizontal)
        #endif
    }
}

// MARK: - Animes View

extension HomeView {
    @ViewBuilder
    func animeItems(
        title: String,
        isLoading: Bool,
        store: Store<HomeReducer.LoadableAnime, HomeReducer.Action>
    ) -> some View {
        WithViewStore(
            store,
            observe: { $0 }
        ) { viewStore in
            if let items = isLoading ? Anime.placeholders(5) : viewStore.value, items.count > 0 {
                VStack(alignment: .leading) {
                    headerText(title)

                    ScrollView(.horizontal, showsIndicators: false) {
                        LazyHStack(alignment: .center, spacing: 12) {
                            ForEach(items) { anime in
                                AnimeItemView(
                                    anime: anime
                                )
                                .onTapGesture {
                                    viewStore.send(.animeTapped(anime))
                                }
                                .disabled(isLoading)
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
        store: Store<HomeReducer.LoadableEpisodes, HomeReducer.Action>
    ) -> some View {
        WithViewStore(
            store,
            observe: { $0 }
        ) { viewStore in
            if let items = viewStore.state.value, items.count > 0 {
                VStack(alignment: .leading) {
                    headerText("Resume Watching")

                    ScrollView(.horizontal, showsIndicators: false) {
                        LazyHStack(alignment: .center) {
                            ForEach(items, id: \.id) { item in
                                ThumbnailItemBigView(
                                    type:
                                        item.episodeStore.isMovie ?
                                        .movie(
                                            image: item.episodeStore.thumbnail?.link,
                                            name: item.episodeStore.title,
                                            progress: item.episodeStore.progress
                                        ) :
                                        .episode(
                                            image: item.episodeStore.thumbnail?.link,
                                            name: item.episodeStore.title,
                                            animeName: item.title,
                                            number: Int(item.episodeStore.number),
                                            progress: item.episodeStore.progress
                                        ),
                                    progressSize: 6
                                )
                                .frame(height: DeviceUtil.isPhone ? 150 : 225)
                                .onTapGesture {
                                    viewStore.send(.resumeWatchingTapped(item))
                                }
                                .contextMenu {
                                    Button {
                                        viewStore.send(.markAsWatched(item))
                                    } label: {
                                        Label(
                                            "Mark as watched",
                                            systemImage: "eye.fill"
                                        )
                                    }
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
                reducer: HomeReducer()
            )
        )
        .preferredColorScheme(.dark)
    }
}
