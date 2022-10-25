//
//  AppView.swift
//  Anime Now! (macOS)
//
//  Created by ErrorErrorError on 9/3/22.
//

import SwiftUI
import ComposableArchitecture

struct AppView: View {
    let store: StoreOf<AppReducer>

    var body: some View {
        WithViewStore(
            store,
            observe: { $0.route }
        ) { viewStore in
            ZStack {
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
        .topSafeAreaInset(tabBar)
        .overlay(
            IfLetStore(
                store.scope(
                    state: \.animeDetail,
                    action: AppReducer.Action.animeDetail
                ),
                then: AnimeDetailView.init(store:)
            )
            .frame(
                maxWidth: .infinity,
                maxHeight: .infinity
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
        .frame(
            minWidth: 1000,
            maxWidth: .infinity,
            minHeight: 500,
            maxHeight: .infinity
        )
    }
}

extension AppView {

    @ViewBuilder
    var tabBar: some View {
        WithViewStore(
            store,
            observe: { $0.route }
        ) { selected in
            HStack(spacing: 32) {
                Text("Anime Now!")
                    .font(.largeTitle.bold())
                    .foregroundColor(.white)

                HStack(spacing: 8) {
                    ForEach(
                        AppReducer.Route.allCases,
                        id: \.self
                    ) { route in
                        Text(route.title)
                            .font(.headline)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 10)
                            .foregroundColor(selected.state == route ? Color.black : Color.white)
                            .background(selected.state == route ? Color.white : Color.clear)
                            .clipShape(Capsule())
                            .contentShape(Rectangle())
                            .onTapGesture {
                                selected.send(
                                    .set(\.$route, route),
                                    animation: .linear(duration: 0.15)
                                )
                            }
                    }
                }
            }
            .padding()
            .frame(
                maxWidth: .infinity,
                alignment: .leading
            )
            .background(
                LinearGradient(
                    stops: [
                        .init(
                            color: .black.opacity(0.75),
                            location: 0.0
                        ),
                        .init(
                            color: .clear,
                            location: 1.0
                        ),
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea(.container, edges: .top)
            )
        }
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
