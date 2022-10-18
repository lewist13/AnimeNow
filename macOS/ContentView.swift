//
//  ContentView.swift
//  Anime Now! (macOS)
//
//  Created by ErrorErrorError on 9/3/22.
//

import SwiftUI
import ComposableArchitecture

struct ContentView: View {
    let store: Store<ContentCore.State, ContentCore.Action>

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
                            action: ContentCore.Action.home
                        )
                    )
                case .search:
                    SearchView(
                        store: store.scope(
                            state: \.search,
                            action: ContentCore.Action.search
                        )
                    )
                case .downloads:
                    DownloadsView(
                        store: store.scope(
                            state: \.downloads,
                            action: ContentCore.Action.downloads
                        )
                    )
                case .collection:
                    CollectionView(
                        store: store.scope(
                            state: \.collection,
                            action: ContentCore.Action.collection
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
                    action: ContentCore.Action.animeDetail
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
                    action: ContentCore.Action.videoPlayer
                ),
                then: AnimeNowVideoPlayer.init(store:)
            )
        )
    }
}

extension ContentView {

    @ViewBuilder
    func tabBar(_ selected: ContentCore.Route) -> some View {
        HStack(spacing: 32) {
//            Text("Anime Now!")
//                .font(.largeTitle.bold())
//                .foregroundColor(.white)

            HStack(spacing: 8) {
                ForEach(
                    ContentCore.Route.allCases,
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
        ContentView(
            store: .init(
                initialState: .init(),
                reducer: ContentCore.reducer,
                environment: .init(
                    animeClient: .mock,
                    mainQueue: .main,
                    mainRunLoop: .main,
                    repositoryClient: RepositoryClientMock.shared,
                    userDefaultsClient: .mock
                )
            )
        )
    }
}
