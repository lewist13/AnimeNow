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

    var body: some View {
//        TabView {

            // MARK: Home View

            HomeView(
                store: store.scope(
                    state: \.home,
                    action: ContentCore.Action.home
                )
            )
            .fullScreenStore(
                store: store.scope(
                    state: \.videoPlayer,
                    action: ContentCore.Action.videoPlayer
                ),
                onDismiss: { },
                destination: { videoPlayerStore in
                    VideoPlayerView(
                        store: videoPlayerStore
                    )
                }
            )
//            .tabItem {
//                Label("Home", systemImage: "house")
//            }

            // MARK: Search View

//            SearchView(
//                store: store.scope(
//                    state: \.search,
//                    action: ContentCore.Action.search
//                )
//            )
//            .tabItem {
//                Label("Search", systemImage: "magnifyingglass")
//            }
//
//            SettingsView(
//                store: store.scope(
//                    state: \.settings,
//                    action: ContentCore.Action.settings
//                )
//            )
//            .tabItem {
//                Label("Settings", systemImage: "gearshape")
//            }
//        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(
            store: .init(
                initialState: .init(),
                reducer: ContentCore.reducer,
                environment: .init(
                    animeClient: .mock,
                    mainRunLoop: .main,
                    videoPlayerClient: .mock,
                    userDefaultsClient: .mock
                )
            )
        )
        .preferredColorScheme(.dark)
    }
}
