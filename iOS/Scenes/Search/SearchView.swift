//
//  SearchView.swift
//  Anime Now!
//
//  Created Erik Bautista on 9/4/22.
//  Copyright © 2022. All rights reserved.
//

import ComposableArchitecture
import SwiftUI

struct SearchView: View {
    let store: Store<SearchCore.State, SearchCore.Action>

    var body: some View {
        VStack {
            WithViewStore(
                store.scope(
                    state: \.query
                )
            ) { viewStore in
                TextField(
                    "Search",
                    text: .init(
                        get: { viewStore.state },
                        set: { query in viewStore.send(.searchQueryChanged(query)) }
                    )
                )
                .padding()
                .background(Color.gray.opacity(0.15))
                .clipShape(Capsule())
            }
            .frame(maxWidth: .infinity)
            .padding()

            WithViewStore(
                store.scope(
                    state: \.loadable
                )
            ) { viewStore in
                switch viewStore.state {
                case .preparing:
                    waitingForTyping
                case .loading:
                    loadingSearches
                case .success(let animes):
                    presentAnimes(animes)
                case .failed:
                    failedToRetrieve
                }
            }
        }
    }
}

extension SearchView {

    @ViewBuilder
    var waitingForTyping: some View {
        VStack(spacing: 16) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 100))

            Text("Start typing to search for animes.")
                .font(.headline)
                .multilineTextAlignment(.center)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .ignoresSafeArea(.keyboard, edges: .bottom)
    }

    @ViewBuilder
    var loadingSearches: some View {
        ProgressView()
            .scaleEffect(1.5)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            .ignoresSafeArea(.keyboard, edges: .bottom)
    }

    @ViewBuilder
    func presentAnimes(_ animes: IdentifiedArrayOf<Anime>) -> some View {
        if animes.count > 0 {
            ScrollView {
                LazyVGrid(
                    columns: [
                        .init(.flexible(), spacing: 16),
                        .init(.flexible(), spacing: 16)
                    ]
                ) {
                    ForEach(animes, id: \.self) { anime in
                        AnimeItemView(anime: anime)
                            .onTapGesture {
                                ViewStore(store.stateless).send(.onAnimeTapped(anime))
                            }
                    }
                }
                .padding([.top, .horizontal])
            }
        } else {
            noResultsFound
        }
    }

    @ViewBuilder
    var failedToRetrieve: some View {
        VStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 22))

            Text("There is an error fetching items.")
                .font(.headline)
                .multilineTextAlignment(.center)
        }
        .foregroundColor(.red)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        .ignoresSafeArea(.keyboard, edges: .bottom)
    }

    @ViewBuilder
    var noResultsFound: some View {
        VStack(spacing: 16) {
            Text("No results found.")
                .font(.title3)
                .bold()
                .multilineTextAlignment(.center)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
    }

}

struct SearchView_Previews: PreviewProvider {
    static var previews: some View {
        SearchView(
            store: .init(
                initialState: .init(
                    loadable: .failed
                ),
                reducer: SearchCore.reducer,
                environment: .init(
                    mainQueue: DispatchQueue.main.eraseToAnyScheduler(),
                    animeClient: .mock
                )
            )
        )
        .preferredColorScheme(.dark)
    }
}
