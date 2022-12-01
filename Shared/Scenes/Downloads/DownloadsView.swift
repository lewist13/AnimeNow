//
//  DownloadsView.swift
//  Anime Now!
//
//  Created by ErrorErrorError on 9/25/22.
//  Copyright © 2022. All rights reserved.
//

import ComposableArchitecture
import SwiftUI

struct DownloadsView: View {
    let store: StoreOf<DownloadsReducer>

    var body: some View {
        WithViewStore(store, observe: \.animes) { viewStore in
            if viewStore.count > 0 {
                StackNavigation(title: "Downloads") {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(viewStore.state) { anime in
                                StackNavigationLink(
                                    title: anime.title
                                ) {
                                    HStack {
                                        FillAspectImage(url: anime.posterImage.first?.link)
                                            .aspectRatio(2/3, contentMode: .fit)
                                            .frame(width: 80)
                                            .cornerRadius(12)

                                        VStack(alignment: .leading) {
                                            Text(anime.title)
                                                .font(.title3.bold())
                                                .foregroundColor(Color.white)

                                            Text("\(anime.episodes.count) Items".uppercased())
                                                .font(.footnote.bold())
                                                .foregroundColor(Color.gray)
                                        }
                                        Spacer()
                                    }
                                    .padding()
                                } destination: {
                                    episodesView(anime)
                                }
                            }
                        }
                    }
                }
            } else {
                VStack(spacing: 12) {
                    Image(systemName: "square.and.arrow.down.fill")
                        .font(.largeTitle)
                        .foregroundColor(Color.gray)
                    
                    Text("Your downloads list is empty")
                        .foregroundColor(.white)
                    
                    Text("To download a show, click on the downloads icon on show details.")
                        .font(.callout)
                        .foregroundColor(.gray)
                }
                .multilineTextAlignment(.center)
                .padding()
            }
        }
        .frame(
            maxWidth: .infinity,
            maxHeight: .infinity
        )
        .onAppear {
            ViewStore(store).send(.onAppear)
        }
    }
}

extension DownloadsView {
    @ViewBuilder
    func episodesView(
        _ anime: AnimeStore
    ) -> some View {
        ScrollView {
            LazyVStack {
                ForEach(anime.episodes.sorted(by: \.number)) { episode in
                    ThumbnailItemCompactView(
                        episode: episode,
                        progress: episode.progress
                    )
                        .frame(height: 84)
                        .frame(maxWidth: .infinity)
                        .onTapGesture {
                            ViewStore(store).send(.playEpisode(anime, anime.episodes.sorted(by: \.number), episode.number))
                        }
                        .contextMenu {
                            Button("Delete Download") {
                                ViewStore(store).send(.deleteEpisode(episode))
                            }
                        }
                }
                .padding(.horizontal)
                .padding(.top)
            }
        }
    }
}

struct DownloadsView_Previews: PreviewProvider {
    static var previews: some View {
        DownloadsView(
            store: .init(
                initialState: .init(),
                reducer: DownloadsReducer()
            )
        )
        .preferredColorScheme(.dark)
    }
}
