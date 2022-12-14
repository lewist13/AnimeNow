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
        StackNavigation(title: "Downloads") {
            WithViewStore(
                store,
                observe: \.animes
            ) { viewStore in
                if viewStore.count > 0 {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(viewStore.state) { anime in
                                StackNavigationLink(
                                    title: anime.title
                                ) {
                                    HStack(spacing: 12) {
                                        FillAspectImage(url: anime.posterImage.first?.link)
                                            .aspectRatio(2/3, contentMode: .fit)
                                            .frame(width: 90)
                                            .cornerRadius(12)

                                        VStack(alignment: .leading) {
                                            Text(anime.title)
                                                .font(.title3.bold())
                                                .foregroundColor(Color.white)

                                            Text(
                                                "\(anime.episodes.count) Item\(anime.episodes.count > 1 ? "s" : "")".uppercased()
                                            )
                                            .font(.footnote.bold())
                                            .foregroundColor(Color.gray)
                                        }

                                        Spacer()
                                    }
                                    .contentShape(Rectangle())
                                    .overlay(
                                        Group {
                                            if anime.downloadingCount > 0 {
                                                Text("\(anime.downloadingCount) Downloading")
                                                    .font(.footnote.bold())
                                                    .foregroundColor(.white)
                                                    .padding(6)
                                                    .background(Capsule().foregroundColor(.secondaryAccent))
                                            }
                                        }
                                            .frame(
                                                maxWidth: .infinity,
                                                maxHeight: .infinity,
                                                alignment: .topTrailing
                                            )
                                    )
                                    .padding()
                                } destination: {
                                    episodesView(anime)
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
        _ anime: DownloaderClient.AnimeStorage
    ) -> some View {
        ScrollView {
            LazyVStack {
                ForEach(anime.episodes.sorted(by: \.number)) { episode in
                    ThumbnailItemCompactView(
                        episode: episode,
                        downloadStatus: episode.downloaded ? nil : .init(state: episode.status)
                    )
                    .animation(.linear, value: episode.status)
                    .frame(height: 84)
                    .frame(maxWidth: .infinity)
                    .onTapGesture {
                        if case .downloaded = episode.status {
                            ViewStore(store).send(.playEpisode(anime, anime.episodes.sorted(by: \.number), episode.number))
                        }
                    }
                    .contextMenu {
                        switch episode.status {
                        case .downloaded:
                            Button("Delete Episode") {
                                ViewStore(store).send(.deleteEpisode(anime.id, episode.number))
                            }
                        case .downloading:
                            Button("Cancel Download") {
                                ViewStore(store).send(.cancelDownload(anime.id, episode.number))
                            }
                        default:
                            EmptyView()
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.top)
            }
        }
    }
}

private extension DownloaderClient.EpisodeStorage {
    var downloaded: Bool {
        switch status {
        case .downloaded:
            return true
        default:
            return false
        }
    }
}

struct DownloadsView_Previews: PreviewProvider {
    static var previews: some View {
        DownloadsView(
            store: .init(
                initialState: .init(
                    animes: [.init(id: 0, title: "Testin", format: .tv, posterImage: [], episodes: [.init(number: 1, title: "Haha", thumbnail: nil, isFiller: false, status: .downloading(progress: 0.5))])]
                ),
                reducer: DownloadsReducer()
            )
        )
        .preferredColorScheme(.dark)
    }
}
