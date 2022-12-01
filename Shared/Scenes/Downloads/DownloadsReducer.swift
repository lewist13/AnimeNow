//
//  DownloadsReducer.swift
//  Anime Now!
//
//  Created by ErrorErrorError on 9/25/22.
//  Copyright © 2022. All rights reserved.
//

import SwiftORM
import ComposableArchitecture

struct DownloadsReducer: ReducerProtocol {
    struct State: Equatable {
        var animes: [AnimeStore] = []
    }

    enum Action: Equatable {
        case onAppear
        case deleteEpisode(EpisodeStore)
        case playEpisode(AnimeStore, [EpisodeStore], Int)
        case onAnimes([AnimeStore])
    }

    @Dependency(\.downloaderClient) var downloaderClient
    @Dependency(\.repositoryClient) var repositoryClient

    var body: some ReducerProtocol<State, Action> {
        Reduce(self.core)
    }
}

extension DownloadsReducer {
    func core(state: inout State, action: Action) -> EffectTask<Action> {
        switch action {
        case .onAppear:
            return .run { send in
                let animes = repositoryClient.observe(AnimeStore.all)

                for await list in animes {
                    let animeLists = list.map { anime in
                        var newAnime = anime
                        newAnime.episodes = newAnime.episodes.filter({ $0.downloadURL != nil })
                        return newAnime
                    }
                        .filter({ $0.episodes.count > 0 })
                    await send(.onAnimes(animeLists))
                }
            }

        case .onAnimes(let animes):
            state.animes = animes

        case .deleteEpisode(let episodeStore):
            guard let url = episodeStore.downloadURL else { break }

            return .run { [episodeStore] _ in
                await downloaderClient.delete(url)
                try await repositoryClient.update(episodeStore.id, \EpisodeStore.downloadURL, nil)
            }

        case .playEpisode:
            break
        }

        return .none
    }
}
