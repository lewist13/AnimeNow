//
//  HomeView.swift
//  Anime Now!
//
//  Created Erik Bautista on 9/4/22.
//  Copyright © 2022. All rights reserved.
//

import ComposableArchitecture
import Kingfisher
import SwiftUI

struct HomeView: View {
    let store: Store<HomeCore.State, HomeCore.Action>

    var body: some View {
        NavigationView {
            WithViewStore(
                store.stateless
            ) { viewStore in
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 24) {
                        animeItems(
                            title: "Trending This Week",
                            store: store.scope(
                                state: \.trendingAnime
                            )
                        )

//                        currentlyWatchingEpisodes(
//                            store: store.scope(
//                                state: \.currentlyWatchingEpisodes
//                            )
//                        )

                        animeItems(
                            title: "Recently Released",
                            store: store.scope(
                                state: \.recentlyReleasedAnime
                            )
                        )
                    }
                }
                .onAppear {
                    viewStore.send(.onAppear)
                }
            }
            .navigationTitle("Anime Now!")
        }
    }
}

extension HomeView {
    @ViewBuilder
    func animeItems(
        title: String,
        store: Store<[Anime], HomeCore.Action>
    ) -> some View {
        VStack(alignment: .leading) {
            Text(title)
                .font(.system(size: 22))
                .bold()
                .padding(.horizontal)

            WithViewStore(store) { viewStore in
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(alignment: .top) {
                        ForEach(viewStore.state, id: \.self) { anime in
                            AnimeItemView(anime: anime)
                                .frame(width: 150)
                                .onTapGesture {
                                    viewStore.send(.tappedAnime)
                                }
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
    }

    @ViewBuilder
    func currentlyWatchingEpisodes(
        store: Store<[Episode], HomeCore.Action>
    ) -> some View {
        VStack(alignment: .leading) {
            Text("Currently Watching")
                .font(.system(size: 21))
                .bold()
                .padding(.horizontal)

            WithViewStore(store) { viewStore in
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(alignment: .top) {
//                        ForEach(viewStore.state, id: \.self) { anime in
//                            AnimeItemView(anime: anime)
//                                .frame(width: 150)
//                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView(
            store: .init(
                initialState: .init(),
                reducer: HomeCore.reducer,
                environment: .init(
                    listClient: .mock
                )
            )
        )
    }
}
