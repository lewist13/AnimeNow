//
//  ContentView.swift
//  Shared
//
//  Created by Erik Bautista on 9/2/22.
//

import SwiftUI
import ComposableArchitecture

struct ContentView: View {
    let store: Store<ContentCore.State, ContentCore.Action>

    @State var visibility = TabBarVisibility.visible

    var body: some View {
        // MARK: Home View

        WithViewStore(
            store.scope(state: \.route)
        ) { viewStore in
            TabBar(
                selection: .init(
                    get: { viewStore.state },
                    set: { viewStore.send(.setRoute($0)) }
                ),
                visibility: $visibility
            ) {
                HomeView(
                    store: store.scope(
                        state: \.home,
                        action: ContentCore.Action.home
                    )
                )
                .tabItem(for: TabBarRoute.home)

                SearchView(
                    store: store.scope(
                        state: \.search,
                        action: ContentCore.Action.search
                    )
                )
                .tabItem(for: TabBarRoute.search)

                DownloadsView(
                    store: store.scope(
                        state: \.downloads,
                        action: ContentCore.Action.downloads
                    )
                )
                .tabItem(for: TabBarRoute.downloads)
            }
            .tabBar(style: AnimeTabBarStyle())
            .tabItem(style: AnimeTabItemStyle())
            .animation(Animation.linear(duration: 0.15), value: viewStore.state)
        }
        .overlay(
            IfLetStore(
                store.scope(
                    state: \.animeDetail,
                    action: ContentCore.Action.animeDetail
                ),
                then: { AnimeDetailView(store: $0) }
            )
        )
        .overlay(
            IfLetStore(
                store.scope(
                    state: \.videoPlayer,
                    action: ContentCore.Action.videoPlayer
                )
            ) {
                VideoPlayerView(
                    store: $0
                )
            }
        )
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(
            store: .init(
                initialState: .init(),
                reducer: ContentCore.reducer,
                environment: .mock
            )
        )
        .preferredColorScheme(.dark)
    }
}
