//
//  DownloadOptionsReducer.swift
//
//
//  Created by ErrorErrorError on 11/24/22.
//

import Utilities
import AnimeClient
import SharedModels
import DownloaderClient
import ComposableArchitecture

public struct DownloadOptionsReducer: ReducerProtocol {
    public init() { }

    public struct State: Equatable {
        public var anime: Anime
        public var episode: Episode

        public var providers = Loadable<[Provider]>.idle
        public var sources = Loadable<[Source]>.idle

        public var providerSelected: Provider.ID?
        public var sourceSelected: Source.ID?

        public init(
            anime: Anime,
            episode: Episode,
            providers: Loadable<[Provider]> = .idle,
            sources: Loadable<[Source]> = .idle,
            providerSelected: Provider.ID? = nil,
            sourceSelected: Source.ID? = nil
        ) {
            self.anime = anime
            self.episode = episode
            self.providers = providers
            self.sources = sources
            self.providerSelected = providerSelected
            self.sourceSelected = sourceSelected
        }
    }

    public enum Action: Equatable {
        case onAppear
        case downloadClicked
        case selectProvider(Provider.ID)
        case selectSource(Source.ID)
        case fetchedProviders(Loadable<[Provider]>)
        case fetchedSources(Loadable<SourcesOptions>)
    }

    public var body: some ReducerProtocol<State, Action> {
        Reduce(self.core)
    }

    @Dependency(\.downloaderClient) var downloaderClient
    @Dependency(\.animeClient) var animeClient
}

extension DownloadOptionsReducer.State {
    var canDownload: Bool {
        source != nil
    }

    var provider: Provider? {
        if let providerSelected {
            return providers.value?[id: providerSelected]
        }
        return nil
    }

    public var source: Source? {
        if let sourceSelected {
            return sources.value?[id: sourceSelected]
        }
        return nil
    }
}

extension DownloadOptionsReducer {
    struct EpisodeProviderCancellable: Hashable {}
    struct SourceOptionsCancellable: Hashable {}

    func core(_ state: inout State, _ action: Action) -> EffectTask<Action> {
        switch action {
        case .onAppear:
            state.providers = .loading
            return .run { [state] send in
                try await withTaskCancellation(id: EpisodeProviderCancellable.self) {
                    let episodes = try await animeClient.getEpisodes(state.anime.id)

                    let episode = episodes.first(where: { $0.number == state.episode.number })

                    if let episode {
                        await send(.fetchedProviders(.success(episode.providers)))
                    } else {
                        await send(.fetchedProviders(.failed))
                    }
                }
            }

        case .fetchedProviders(let loadable):
            state.providers = loadable
            state.providerSelected = loadable.value?.first?.id
            return fetchSource(&state)

        case .fetchedSources(let loadable):
            let newLoadable = loadable.map { $0.sources.filter { source in source.quality != .autoalt && source.quality != .auto } }
            state.sources = newLoadable
            state.sourceSelected = newLoadable.value?.first?.id

        case .selectProvider(let providerId):
            if state.providerSelected != providerId {
                state.providerSelected = providerId
                return fetchSource(&state)
            }

        case .selectSource(let sourceId):
            state.sourceSelected = sourceId

        case .downloadClicked:
            break
        }
        return .none
    }

    func fetchSource(_ state: inout State) -> EffectTask<Action> {
        if let provider = state.provider {
            state.sources = .loading
            state.sourceSelected = nil
            return .run { send in
                await withTaskCancellation(id: SourceOptionsCancellable.self, cancelInFlight: true) {
                    do {
                        await send(.fetchedSources(.success(try await animeClient.getSources(provider))))
                    } catch {
                        await send(.fetchedSources(.failed))
                    }
                }
            }
        } else {
            state.sources = .idle
            state.sourceSelected = nil
        }

        return .none
    }
}
