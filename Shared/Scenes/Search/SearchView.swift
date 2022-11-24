//
//  SearchView.swift
//  Anime Now!
//
//  Created by ErrorErrorError on 9/4/22.
//  Copyright © 2022. All rights reserved.
//

import ComposableArchitecture
import SwiftUI

struct SearchView: View {
    let store: StoreOf<SearchReducer>

    var body: some View {
        VStack {
            ExtraTopSafeAreaInset()
                .fixedSize()

            WithViewStore(
                store,
                observe: { $0 }
            ) { viewStore in
                HStack {
                    TextField(
                        "Search",
                        text: viewStore.binding(
                            get: \.query,
                            send: SearchReducer.Action.searchQueryChanged
                        )
                        .removeDuplicates()
                    )
                    .textFieldStyle(.plain)
                    .frame(maxHeight: .infinity)

                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 20))
                        .frame(maxHeight: .infinity)
                        .onTapGesture {
                            viewStore.send(
                                .searchQueryChanged("")
                            )
                        }
                        .opacity(viewStore.query.count > 0 ? 1.0 : 0.0)
                }
                .fixedSize(horizontal: false, vertical: true)
                .padding()
                .background(Color.gray.opacity(0.15))
                .clipShape(Capsule())
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal)

            WithViewStore(
                store.scope(
                    state: \.loadable
                )
            ) { viewStore in
                switch viewStore.state {
                case .idle:
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
    var searchHistory: some View {
        WithViewStore(
            store,
            observe: \.searched
        ) { viewStore in
            if viewStore.state.count > 0 {
                VStack(alignment: .leading) {
                    HStack {
                        Text("Search History")
                            .bold()
                            .foregroundColor(.gray)
                        Spacer()
                        Text("Clear")
                            .foregroundColor(.red)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                viewStore.send(
                                    .clearSearchHistory,
                                    animation: .easeInOut(duration: 0.25)
                                )
                            }
                    }
                    .font(.body)

                    ScrollView(.horizontal) {
                        HStack {
                            ForEach(
                                Array(zip(viewStore.state.indices, viewStore.state)),
                                id: \.0
                            ) { index, search in
                                ChipView(text: search)
                                    .onTapGesture {
                                        viewStore.send(.searchQueryChanged(search))
                                    }
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    @ViewBuilder
    var waitingForTyping: some View {
        VStack(spacing: 16) {
            searchHistory
            Spacer()
            Image(systemName: "magnifyingglass")
                .font(.system(size: 70))

            Text("Start typing to search for animes.")
                .font(.headline)
                .multilineTextAlignment(.center)
            Spacer()
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
    func presentAnimes(_ animes: [Anime]) -> some View {
        if animes.count > 0 {
            ScrollView {
                ZStack {
                    VStack {
                        LazyVGrid(
                            columns: .init(
                                repeating: .init(
                                    .flexible(),
                                    spacing: 16
                                ),
                                count: DeviceUtil.isPhone ? 2 : 6
                            )
                        ) {
                            ForEach(animes, id: \.id) { anime in
                                AnimeItemView(anime: anime)
                                    .onTapGesture {
                                        ViewStore(store.stateless).send(.onAnimeTapped(anime))
                                        #if os(iOS)
                                        UIApplication.shared.endEditing(true)
                                        #endif
                                    }
                            }
                        }
                        .padding([.top, .horizontal])

                        ExtraBottomSafeAreaInset()
                        Spacer(minLength: 32)
                    }

                    #if os(iOS)
                    GeometryReader { reader in
                        Color.clear
                            .onChange(
                                of: reader.frame(in: .named("scroll")).minY
                            ) { newValue in
                                UIApplication.shared.endEditing(true)
                            }
                    }
                    #endif
                }
            }
            .coordinateSpace(name: "scroll")
        } else {
            noResultsFound
        }
    }

    @ViewBuilder
    var failedToRetrieve: some View {
        VStack(spacing: 8) {
            searchHistory
            Spacer()
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 22))

            Text("There is an error fetching items.")
                .font(.headline)
                .multilineTextAlignment(.center)
            Spacer()
        }
        .foregroundColor(.red)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        .ignoresSafeArea(.keyboard, edges: .bottom)
    }

    @ViewBuilder
    var noResultsFound: some View {
        VStack(spacing: 16) {
            searchHistory
            Spacer()
            Text("No results found.")
                .font(.title3)
                .bold()
                .multilineTextAlignment(.center)
            Spacer()
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
                    query: "Test",
                    loadable: .success([]),
                    searched: ["Testy", "Attack on Titans"]
                ),
                reducer: SearchReducer()
            )
        )
        .preferredColorScheme(.dark)
    }
}
