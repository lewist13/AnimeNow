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
                                ThumbnailItemCompactView(
                                    episode: episode
                                )
                                .overlay(
                                    selectedOverlay(episode.id == viewStore.selectedId)
                                )
                                .onTapGesture {
                                    if viewStore.selectedId != episode.id {
                                        viewStore.send(.aboutToChangeEpisode(to: episode.id))
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

extension SidebarEpisodesView {
    @ViewBuilder
    func selectedOverlay(_ selected: Bool) -> some View {
        if selected {
            Text("Now Playing")
                .font(.caption2.weight(.heavy))
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.white)
                .foregroundColor(Color.black)
                .clipShape(Capsule())
                .shadow(
                    color: Color.black.opacity(0.5),
                    radius: 16,
                    x: 0,
                    y: 0
                )
                .frame(
                    maxWidth: .infinity,
                    maxHeight: .infinity,
                    alignment: .bottomLeading
                )
                .padding(6)
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
                environment: .init(
                    mainQueue: .main.eraseToAnyScheduler(),
                    animeClient: .mock
                )
            )
        )
        .preferredColorScheme(.dark)
        .background(BlurView(style: .systemUltraThinMaterialDark))
    }
}
