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
                ScrollView(.vertical) {
                    VStack(alignment: .leading) {
                        // Trending Items
                        trendingItems(
                            store: store.scope(
                                state: \.trendingAnime
                            )
                        )
                    }
                }
                .onAppear {
                    viewStore.send(.onAppear)
                }
            }
            .navigationViewStyle(.stack)
            .navigationBarTitleDisplayMode(.inline)
            .navigationTitle("Anime Now!")
        }
    }
}

extension HomeView {
    @ViewBuilder
    func trendingItems(store: Store<[Anime], HomeCore.Action>) -> some View {
        Group {
            Text("Trending Shows")
                .font(.system(size: 21))
                .bold()
                .padding(.horizontal)

            WithViewStore(store) { viewStore in
                ScrollView(.horizontal) {
                    HStack(alignment: .top) {
                        ForEach(viewStore.state, id: \.self) { anime in
                            TrendingAnimeItemView(anime: anime)
                        }
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
                    animeList: .mock
                )
            )
        )
    }
}
