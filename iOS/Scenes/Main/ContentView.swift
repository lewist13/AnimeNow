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

        // MARK: Home View

        WithViewStore(
            store.scope(state: \.route)
        ) { viewStore in
            Group {
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
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .overlay(
                HStack(spacing: 0) {
                    ForEach(ContentCore.Route.allCases, id: \.self) { item in
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
                                .binding(.set(\.$route, item)),
                                animation: .linear(duration: 0.15)
                            )
                        }
                    }
                }
                    .padding(.horizontal, 12)
                    .background(Color(white: 0.08))
                    .clipShape(Capsule())
                    .frame(
                        maxWidth: .infinity,
                        maxHeight: .infinity,
                        alignment: .bottom
                    )
                    .ignoresSafeArea(.keyboard, edges: .bottom)
            )
        }
//        .sheetStore(
//            store: store.scope(
//                state: \.animeDetail,
//                action: ContentCore.Action.animeDetail
//            ),
//            onDismiss: {
//                ViewStore(store.stateless).send(.animeDetail(.closeButtonPressed))
//            },
//            destination: AnimeDetailView.init(store:)
//        )
        .overlay(
            IfLetStore(
                store.scope(
                    state: \.animeDetail,
                    action: ContentCore.Action.animeDetail
                ),
                then: AnimeDetailView.init(store:)
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
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .preferredColorScheme(.dark)
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
