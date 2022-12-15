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
                observe: \.animes.count
            ) { viewStore in
                if viewStore.state > 0 {
                    ScrollView {
                        WithViewStore(
                            store,
                            observe: \.animes
                        ) { animes in
                            if DeviceUtil.isPhone {
                                rowAnimesView(animes.state)
                            } else {
                                gridAnimesView(animes.state)
                            }
                        }
                    }
                } else {
                    noItems
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
    var noItems: some View {
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

extension DownloadsView {
    @ViewBuilder
    func rowAnimesView(
        _ animes: [DownloaderClient.AnimeStorage]
    ) -> some View {
        LazyVStack(spacing: 12) {
            ForEach(animes) { anime in
                StackNavigationLink(
                    title: anime.title
                ) {
                    HStack(spacing: 12) {
                        FillAspectImage(url: anime.posterImage.first?.link)
                            .aspectRatio(2/3, contentMode: .fit)
                            .frame(width: 100)
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
                } destination: {
                    episodesView(anime)
                }
            }
            .padding(.horizontal)
        }
    }

    @ViewBuilder
    func gridAnimesView(
        _ animes: [DownloaderClient.AnimeStorage]
    ) -> some View {
        LazyVGrid(
            columns: [
                .init(
                    .adaptive(minimum: 180),
                    spacing: 12
                )
            ],
            spacing: 12
        ) {
            ForEach(animes) { anime in
                StackNavigationLink(
                    title: anime.title
                ) {
                    VStack(
                        alignment: .leading,
                        spacing: 16
                    ) {
                        AnimeItemView(anime: anime)
                            .cornerRadius(12)
                            .overlay(
                                ZStack {
                                    if anime.downloadingCount > 0 {
                                        Circle()
                                            .foregroundColor(.secondaryAccent)
                                            .frame(width: 24, height: 24)
                                        
                                        Text("\(anime.downloadingCount)")
                                            .font(.caption.bold())
                                            .foregroundColor(.white)
                                    }
                                }
                                    .padding(8)
                                    .frame(
                                        maxWidth: .infinity,
                                        maxHeight: .infinity,
                                        alignment: .topTrailing
                                    )
                            )
                        Text(
                            "\(anime.episodes.count) EPISODE\(anime.episodes.count > 1 ? "S" : "")"
                        )
                        .foregroundColor(.gray)
                        .font(.callout.weight(.bold))
                    }
                } destination: {
                    episodesView(anime)
                }
            }
        }
        .padding(.top)
        .padding(.horizontal)
    }
}

extension DownloadsView {
    @ViewBuilder
    func episodesView(
        _ anime: DownloaderClient.AnimeStorage
    ) -> some View {
        ScrollView {
            if DeviceUtil.isPhone {
                rowEpisodesView(anime)
            } else {
                gridEpisodesView(anime)
            }
        }
    }

    @ViewBuilder
    func rowEpisodesView(
        _ anime: DownloaderClient.AnimeStorage
    ) -> some View {
        LazyVStack(spacing: 12) {
            ForEach(anime.episodes.sorted(by: \.number)) { episode in
                ThumbnailItemCompactView(
                    episode: episode,
                    downloadStatus: episode.downloaded ? nil : .init(
                        state: episode.status,
                        callback: { action in
                            let viewStore = ViewStore(store)
                            switch action {
                            case .download:
                                break
                            case .cancel:
                                viewStore.send(.cancelDownload(anime.id, episode.number))
                            case .retry:
                                break
                            }
                        }
                    )
                )
                .frame(height: 84)
                .frame(maxWidth: .infinity)
                .animation(.linear, value: episode.status)
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
                    case .downloading, .pending:
                        Button("Cancel Download") {
                            ViewStore(store).send(.cancelDownload(anime.id, episode.number))
                        }
                    default:
                        EmptyView()
                    }
                }
            }
            .padding(.horizontal)
        }
    }

    @ViewBuilder
    func gridEpisodesView(
        _ anime: DownloaderClient.AnimeStorage
    ) -> some View {
        LazyVGrid(
            columns: [
                .init(
                    .adaptive(minimum: 300),
                    spacing: 12
                )
            ],
            spacing: 12
        ) {
            ForEach(
                anime.episodes.sorted(by: \.number)
            ) { episode in
                ThumbnailItemBigView(
                    episode: episode,
                    downloadStatus: episode.downloaded ? nil : .init(
                        state: episode.status,
                        callback: { action in
                            let viewStore = ViewStore(store)
                            switch action {
                            case .cancel:
                                viewStore.send(.cancelDownload(anime.id, episode.number))
                            default:
                                break
                            }
                        }
                    )
                )
                .animation(.linear, value: episode.status)
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
                    case .downloading, .pending:
                        Button("Cancel Download") {
                            ViewStore(store).send(.cancelDownload(anime.id, episode.number))
                        }
                    default:
                        EmptyView()
                    }
                }
            }
        }
        .padding(.horizontal)
        .padding(.top)
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
                    animes: [.init(id: 0, title: "Testing", format: .tv, posterImage: [], episodes: [.init(number: 1, title: "Haha", thumbnail: nil, isFiller: false, status: .downloading(progress: 0.5))])]
                ),
                reducer: EmptyReducer()
            )
        )
        .preferredColorScheme(.dark)
    }
}
