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
            observe: \.route
        ) { viewStore in
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
                CollectionsView(
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
        #if os(iOS)
        .bottomSafeAreaInset(tabBar)
        .ignoresSafeArea(.keyboard, edges: .bottom)
        #else
        .topSafeAreaInset(tabBar)
        .frame(
            minWidth: 1000,
            minHeight: 650
        )
        #endif
        .background(Color.black.ignoresSafeArea())
        .preferredColorScheme(.dark)
        .overlay(
            IfLetStore(
                store.scope(
                    state: \.animeDetail,
                    action: AppReducer.Action.animeDetail
                ),
                then: AnimeDetailView.init
            )
        )
        .overlay(
            IfLetStore(
                store.scope(
                    state: \.modalOverlay,
                    action: AppReducer.Action.modalOverlay
                ),
                then: ModalOverlayView.init
            )
        )
        .overlay(
            IfLetStore(
                store.scope(
                    state: \.videoPlayer,
                    action: AppReducer.Action.videoPlayer
                ),
                then: AnimePlayerView.init
            )
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct AppView_Previews: PreviewProvider {
    static var previews: some View {
        AppView(
            store: .init(
                initialState: .init(),
                reducer: AppReducer()
            )
        )
    }
}
