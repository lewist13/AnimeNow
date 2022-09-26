//
//  SidebarEpisodesView.swift
//  Anime Now! (iOS)
//
//  Created by Erik Bautista on 9/22/22.
//

import SwiftUI
import Kingfisher
import ComposableArchitecture

struct SidebarEpisodesView: View {
    let store: Store<SidebarEpisodesCore.State, SidebarEpisodesCore.Action>

    var body: some View {
            ScrollViewReader { proxy in
                ScrollView(
                    .vertical,
                    showsIndicators: false
                ) {
                    WithViewStore(store) { viewStore in
                        LazyVStack {
                            ForEach(viewStore.episodes) { episode in
                                EpisodeItemCompactView(
                                    episode: episode,
                                    selected: episode.id == viewStore.selectedId
                                )
                                .onTapGesture {
                                    if viewStore.selectedId != episode.id {
                                        viewStore.send(.selected(id: episode.id))
                                    }
                                }
                                .id(episode.id)
                            }
                        }
                        .padding([.bottom])
                        .onAppear {
                            proxy.scrollTo(viewStore.selectedId, anchor: .top)
                        }
                        .onChange(of: viewStore.selectedId) { newValue in
                            withAnimation {
                                proxy.scrollTo(newValue, anchor: .top)
                            }
                        }
                    }
                }
            }
    }
}

struct SidebarEpisodesView_Previews: PreviewProvider {
    static var previews: some View {
        SidebarEpisodesView(
            store: .init(
                initialState: .init(
                    episodes: .init(uniqueElements: Episode.demoEpisodes),
                    selectedId: Episode.demoEpisodes.first!.id
                ),
                reducer: SidebarEpisodesCore.reducer,
                environment: .init()
            )
        )
        .preferredColorScheme(.dark)
        .background(BlurView(style: .systemUltraThinMaterialDark))
    }
}
