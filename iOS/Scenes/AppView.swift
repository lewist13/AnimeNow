//
//  AppView.swift
//  Shared
//
//  Created by ErrorErrorError on 9/2/22.
//

import SwiftUI
import ComposableArchitecture

struct AppView: View {
    let store: StoreOf<AppReducer>

    var body: some View {

        // MARK: Content View

        WithViewStore(
            store,
            observe: { $0.route }
        ) { viewStore in
            Group {
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

                case .collection:
                    CollectionView(
                        store: store.scope(
                            state: \.collection,
                            action: AppReducer.Action.collection
                        )
                    )

                case .downloads:
                    DownloadsView(
                        store: store.scope(
                            state: \.downloads,
                            action: AppReducer.Action.downloads
                        )
                    )
                }
            }
            .frame(
                maxWidth: .infinity,
                maxHeight: .infinity
            )
            .background(Color.black.ignoresSafeArea())
            .preferredColorScheme(.dark)
            .bottomSafeAreaInset(
                HStack(spacing: 0) {
                    ForEach(
                        AppReducer.Route.allCases,
                        id: \.self
                    ) { item in
                        Image(
                            systemName: "\(item == viewStore.state ? item.selectedIcon : item.icon)"
                        )
                        .foregroundColor(
                            item == viewStore.state ? Color.white : Color.gray
                        )
                        .font(.system(size: 20).weight(.semibold))
                        .frame(
                            width: 56,
                            height: 56,
                            alignment: .center
                        )
                        .onTapGesture {
                            viewStore.send(
                                .set(\.$route, item),
                                animation: .linear(duration: 0.15)
                            )
                        }
                    }
                }
                    .padding(.horizontal, 12)
                    .background(Color(white: 0.08))
                    .clipShape(Capsule())
                    .padding(.bottom, DeviceUtil.hasBottomIndicator ? 0 : 24)
            )
            .ignoresSafeArea(.keyboard, edges: .bottom)
        }
        .overlay(
            IfLetStore(
                store.scope(
                    state: \.animeDetail,
                    action: AppReducer.Action.animeDetail
                ),
                then: { store in
                    AnimeDetailView(store: store)
                        .statusBar(hidden: true)
                }
            )
        )
        .overlay(
            IfLetStore(
                store.scope(
                    state: \.videoPlayer,
                    action: AppReducer.Action.videoPlayer
                ),
                then: { store in
                  AnimePlayerView(store: store)
                    .statusBar(hidden: true)
                    .prefersHomeIndicatorAutoHidden(true)
                    .supportedOrientation(.landscape)
                }
            )
            .transition(.opacity)
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity)
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
