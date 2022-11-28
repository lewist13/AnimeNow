//  DownloadOptionsReducer.swift
//  Anime Now! (iOS)
//
//  Created by ErrorErrorError on 11/24/22.
//

import ComposableArchitecture

struct DownloadOptionsReducer: ReducerProtocol {
    struct State: Equatable {
        let animeId: Anime.ID
        let episodeNumber: Int
        var providers = Loadable<[Provider]>.idle
        var sourcesOptions = Loadable<SourcesOptions>.idle

        var providerSelected: Provider.ID?
        var sourceSelected: Source.ID?
    }

    enum Action: Equatable {
        case onAppear
        case downloadClicked
        case selectProvider(Provider.ID)
        case selectSource(Source.ID)
        case fetchedProviders(Loadable<[Provider]>)
        case fetchedSources(Loadable<SourcesOptions>)
    }

    var body: some ReducerProtocol<State, Action> {
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

    var source: Source? {
        if let sourceSelected {
            return sourcesOptions.value?.sources[id: sourceSelected]
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
                    let episodes = try await animeClient.getEpisodes(state.animeId)

                    let episode = episodes.first(where: { $0.number == state.episodeNumber })

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
            state.sourcesOptions = loadable
            state.sourceSelected = loadable.value?.sources.first?.id

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
            state.sourcesOptions = .loading
            state.sourceSelected = nil
            return .run { send in
                await withTaskCancellation(id: SourceOptionsCancellable.self) {
                    do {
                        await send(.fetchedSources(.success(try await animeClient.getSources(provider))))
                    } catch {
                        await send(.fetchedSources(.failed))
                    }
                }
            }
        } else {
            state.sourcesOptions = .idle
            state.sourceSelected = nil
        }

        return .none
    }
}
