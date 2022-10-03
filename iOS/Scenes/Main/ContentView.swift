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
                selection: viewStore.binding(\.$route, as: \.self),
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
                VideoPlayerV2View(
                    store: $0
                )
            }
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct AnimeTabBarStyle: TabBarStyle {
    public func tabBar(with geometry: GeometryProxy, itemsContainer: @escaping () -> AnyView) -> some View {
        itemsContainer()
            .padding(.horizontal)
            .background(Color(hue: 0, saturation: 0, brightness: 0.03))
            .cornerRadius(geometry.size.height / 4)
            .fixedSize()
            .padding(.vertical, 28)
            .frame(maxWidth: .infinity)
    }
}

struct AnimeTabItemStyle: TabItemStyle {
    public func tabItem(item: TabBarRoute, isSelected: Bool) -> some View {
        Image(systemName: "\(isSelected ? item.selectedIcon : item.icon)")
            .font(.system(size: 20).weight(.semibold))
            .frame(width: 58, height: 58)
            .foregroundColor(isSelected ? Color.red : Color.white)
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
