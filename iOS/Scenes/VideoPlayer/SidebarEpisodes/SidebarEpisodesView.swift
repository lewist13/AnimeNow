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
        WithViewStore(store) { viewStore in
            ScrollViewReader.init { proxy in
                ScrollView(
                    .vertical,
                    showsIndicators: false
                ) {
                    LazyVStack {
                        ForEach(viewStore.episodes) { episode in
                            EpisodeItemCompactView(episode: episode)
                                .onTapGesture {
                                    viewStore.send(.selected(id: episode.id))
                                }
                                .id(episode.id)
                        }
                    }
                    .padding([.bottom])
                }
                .onAppear {
                    proxy.scrollTo(viewStore.selectedId)
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
        .background(BlurView(style: .systemUltraThinMaterialDark))
    }
}
