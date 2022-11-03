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
                    )
                    .textFieldStyle(.plain)
                    .frame(maxHeight: .infinity)

                    if viewStore.query.count > 0 {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 20))
                            .frame(maxHeight: .infinity)
                            .onTapGesture {
                                viewStore.send(
                                    .searchQueryChanged("")
                                )
                            }
                    }
                }
                .fixedSize(horizontal: false, vertical: true)
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
                    loadable: .success([]),
                    query: "Test"
                ),
                reducer: SearchReducer()
            )
        )
        .preferredColorScheme(.dark)
    }
}
