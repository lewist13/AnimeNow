//
//  AppView.swift
//  Anime Now! (macOS)
//
//  Created by ErrorErrorError on 9/3/22.
//

import SwiftUI
import ComposableArchitecture

struct AppView: View {
    let store: Store<AppReducer.State, AppReducer.Action>

    var body: some View {
        WithViewStore(
            store.scope(
                state: \.route
            )
        ) { viewStore in
            VStack(spacing: 0) {
                tabBar(viewStore.state)

                switch viewStore.state {
                case .home:
                    HomeView(
                        store: store.scope(
                            state: \.home,
                            action: AppReducer.Action.home
                        )
                    )
                case .search:
                    SearchView(
                        store: store.scope(
                            state: \.search,
                            action: AppReducer.Action.search
                        )
                    )
                case .downloads:
                    DownloadsView(
                        store: store.scope(
                            state: \.downloads,
                            action: AppReducer.Action.downloads
                        )
                    )
                case .collection:
                    CollectionView(
                        store: store.scope(
                            state: \.collection,
                            action: AppReducer.Action.collection
                        )
                    )
                }
            }
            .frame(maxWidth: 1700, alignment: .leading)
        }
        .frame(
            minWidth: 1000,
            maxWidth: .infinity,
            minHeight: 300,
            maxHeight: .infinity
        )
        .overlay(
            IfLetStore(
                store.scope(
                    state: \.animeDetail,
                    action: AppReducer.Action.animeDetail
                ),
                then: AnimeDetailView.init(store:)
            )
            .frame(
                maxWidth: 500,
                maxHeight: 700
            )
        )
        .overlay(
            IfLetStore(
                store.scope(
                    state: \.videoPlayer,
                    action: AppReducer.Action.videoPlayer
                ),
                then: AnimePlayerView.init(store:)
            )
        )
    }
}

extension AppView {

    @ViewBuilder
    func tabBar(_ selected: AppReducer.Route) -> some View {
        HStack(spacing: 32) {
//            Text("Anime Now!")
//                .font(.largeTitle.bold())
//                .foregroundColor(.white)

            HStack(spacing: 8) {
                ForEach(
                    AppReducer.Route.allCases,
                    id: \.self
                ) { route in
                    Text(route.title)
                        .font(.headline)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .foregroundColor(selected == route ? Color.black : Color.white)
                        .background(selected == route ? Color.white : Color.clear)
                        .clipShape(Capsule())
                        .contentShape(Rectangle())
                        .onTapGesture {
                            ViewStore(store.stateless).send(
                                .binding(.set(\.$route, route)),
                                animation: .linear(duration: 0.15)
                            )
                        }
                }
            }
            .background(Color.gray.opacity(0.1))
            .clipShape(Capsule())
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .center)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        AppView(
            store: .init(
                initialState: .init(),
                reducer: AppReducer()
            )
        )
    }
}
