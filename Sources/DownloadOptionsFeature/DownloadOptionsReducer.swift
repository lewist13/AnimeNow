//
//  DownloadOptionsReducer.swift
//
//
//  Created by ErrorErrorError on 11/24/22.
//

import Utilities
import AnimeClient
import SharedModels
import AnimeStreamLogic
import DownloaderClient
import ComposableArchitecture

public struct DownloadOptionsReducer: ReducerProtocol {
    public init() { }

    public struct State: Equatable {
        public let anime: Anime
        public var stream: AnimeStreamLogic.State

        public init(
            anime: Anime,
            episodeId: Episode.ID,
            availableProviders: Selectable<ProviderInfo>
        ) {
            self.anime = anime
            self.stream = .init(
                animeId: anime.id,
                episodeId: episodeId,
                availableProviders: availableProviders
            )
        }
    }

    public enum Action: Equatable {
        case onAppear
        case downloadClicked
        case animeStream(AnimeStreamLogic.Action)
    }

    public var body: some ReducerProtocol<State, Action> {
        Scope(state: \.stream, action: /Action.animeStream) {
            AnimeStreamLogic()
        }

        Reduce(self.core)
    }

    @Dependency(\.downloaderClient) var downloaderClient
    @Dependency(\.animeClient) var animeClient
}

extension DownloadOptionsReducer.State {
    var canDownload: Bool {
        stream.source != nil
    }
}

extension DownloadOptionsReducer {
    func core(_ state: inout State, _ action: Action) -> EffectTask<Action> {
        switch action {
        case .onAppear:
            return .action(.animeStream(.initialize))
        case .downloadClicked:
            break
        case .animeStream:
            break
        }
        return .none
    }
}
