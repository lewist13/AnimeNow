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
        var animes: [DownloaderClient.AnimeStorage] = []
    }

    enum Action: Equatable {
        case onAppear
        case deleteEpisode(Anime.ID, Int)
        case cancelDownload(Anime.ID, Int)
        case playEpisode(DownloaderClient.AnimeStorage, [DownloaderClient.EpisodeStorage], Int)
        case onAnimes([DownloaderClient.AnimeStorage])
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
                let list = downloaderClient.observe(nil)

                for await animes in list {
                    await send(.onAnimes(animes.sorted(by: \.title)))
                }
            }

        case .onAnimes(let animes):
            state.animes = animes

        case .deleteEpisode(let animeId, let episodeNumber):
            return .run {
                await downloaderClient.delete(animeId, episodeNumber)
            }

        case .cancelDownload(let animeId, let episodeNumber):
            return .run {
                await downloaderClient.cancel(animeId, episodeNumber)
            }

        case .playEpisode:
            break
        }

        return .none
    }
}
