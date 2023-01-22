//
//  AnimeStreamLogic.swift
//  
//
//  Created by ErrorErrorError on 1/5/23.
//  
//

import Utilities
import AnimeClient
import SharedModels
import UserDefaultsClient
import ComposableArchitecture

public struct AnimeStreamViewState: Equatable {
    public let availableProviders: Selectable<ProviderInfo>
    public let links: Selectable<EpisodeLink>
    public let sources: Selectable<Source>

    public let loadingLink: Bool
    public let loadingSource: Bool

    public init(
        availableProviders: Selectable<ProviderInfo>,
        links: Selectable<EpisodeLink>,
        qualities: Selectable<Source>,
        loadingLink: Bool,
        loadingSource: Bool
    ) {
        self.availableProviders = availableProviders
        self.links = links
        self.sources = qualities
        self.loadingLink = loadingLink
        self.loadingSource = loadingSource
    }
}

extension AnimeStreamViewState {
    public init(_ state: AnimeStreamLogic.State) {
        self.init(
            availableProviders: state.availableProviders,
            links: .init(
                items: state.episode?.links.sorted(by: \.description) ?? .init(),
                selected: state.selectedLink
            ),
            qualities: .init(
                items: state.sourceOptions.value?.sources ?? [], selected: state.selectedSource
            ),
            loadingLink: state.loadingProvider,
            loadingSource: !state.sourceOptions.finished
        )
    }
}

public struct AnimeStreamLogic: ReducerProtocol {
    public init() { }

    public struct State: Equatable {
        public let animeId: Anime.ID
        public var selectedEpisode: Episode.ID

        public var availableProviders: Selectable<ProviderInfo>
        public var streamingProviders = [AnimeStreamingProvider.ID: Loadable<AnimeStreamingProvider>]()
        public var selectedLink: EpisodeLink.ID?
        public var sourceOptions = Loadable<SourcesOptions>.idle
        public var selectedSource: Source.ID?

        public init(
            animeId: Anime.ID,
            episodeId: Episode.ID,
            availableProviders: Selectable<ProviderInfo>,
            streamingProviders: [AnimeStreamingProvider] = []
        ) {
            self.animeId = animeId
            self.selectedEpisode = episodeId
            self.availableProviders = availableProviders
            self.streamingProviders = .init(uniqueKeysWithValues: streamingProviders.map { ($0.name, .success($0)) })
        }
    }

    public enum Action: Equatable {
        case initialize
        case destroy
        case selectEpisode(Episode.ID)
        case selectProvider(ProviderInfo.ID)
        case selectLink(EpisodeLink.ID)
        case fetchedProvider(AnimeStreamingProvider)
        case fetchedSources(Loadable<SourcesOptions>)
        case selectSource(Source.ID)
    }

    public var body: some ReducerProtocol<State, Action> {
        Reduce(self.core)
    }

    @Dependency(\.animeClient) var animeClient
    @Dependency(\.userDefaultsClient) var userDefaultsClient
}

extension AnimeStreamLogic.State {
    var loadingProvider: Bool {
        if let selected = availableProviders.selected {
            return !(streamingProviders[selected]?.finished ?? true)
        }
        return false
    }
}

extension AnimeStreamLogic.State {
    public var episode: Episode? {
        streamingProvider?.episodes[id: selectedEpisode]
    }

    public var link: EpisodeLink? {
        if let selectedLink {
            return episode?.links[id: selectedLink]
        }
        return nil
    }

    public var source: Source? {
        if let sourceOptions = sourceOptions.value, let selectedSource {
            return sourceOptions.sources[id: selectedSource]
        }
        return nil
    }

    public var streamingProvider: AnimeStreamingProvider? {
        if let selectedProvider = availableProviders.selected {
            return streamingProviders[selectedProvider]?.value
        }
        return nil
    }

    public var loadableStreamingProvider: Loadable<AnimeStreamingProvider>? {
        if let selectedProvider = availableProviders.selected {
            return streamingProviders[selectedProvider]
        }
        return nil
    }
}

extension AnimeStreamLogic {
    struct FetchProviderCancellable: Hashable {}
    struct FetchSourceOptionsCancellable: Hashable {}

    func core(_ state: inout State, _ action: Action) -> EffectTask<Action> {
        switch action {
        case .initialize:
            state.availableProviders.selected = state.availableProviders.selected ?? "Gogoanime"
            return fetchStreamingProvider(&state)

        case .fetchedProvider(let provider):
            state.streamingProviders[provider.id] = .success(provider)
            return fetchLinkOptions(&state)

        case .fetchedSources(let loadable):
            state.sourceOptions = loadable

            var preferredQuality: Source.ID?

            if let quality = userDefaultsClient.get(.videoPlayerQuality) {
                preferredQuality = loadable.value?.sources.first { $0.quality == quality }?.id
            }

            state.selectedSource = state.selectedSource ?? preferredQuality ?? loadable.value?.sources.first?.id

        case .selectEpisode(let episodeId):
            if state.selectedEpisode != episodeId {
                state.selectedEpisode = episodeId
                state.selectedLink = nil
                state.selectedSource = nil
                state.sourceOptions = .idle
                return fetchLinkOptions(&state)
            }

        case .selectProvider(let providerId):
            if state.availableProviders.selected != providerId {
                state.availableProviders.selected = providerId
                state.selectedSource = nil
                state.selectedLink = nil
                state.sourceOptions = .idle
                return fetchStreamingProvider(&state)
            }

        case .selectLink(let episodeLink):
            if state.selectedLink != episodeLink {
                state.selectedLink = episodeLink
                state.selectedSource = nil
                state.sourceOptions = .idle
                let audio = state.link?.audio
                return .merge(
                    fetchLinkOptions(&state),
                    .run {
                        await userDefaultsClient.set(.videoPlayerAudio, value: audio)
                    }
                )
            }

        case .selectSource(let sourceId):
            if state.selectedSource != sourceId {
                state.selectedSource = sourceId
                let quality = state.source?.quality
                return .run {
                    await userDefaultsClient.set(.videoPlayerQuality, value: quality)
                }
            }

        case .destroy:
            return .merge(
                .cancel(id: FetchProviderCancellable.self),
                .cancel(id: FetchSourceOptionsCancellable.self)
            )
        }

        return .none
    }

    private func fetchStreamingProvider(_ state: inout State) -> EffectTask<Action> {
        if let provider = state.availableProviders.item {
            if (state.streamingProviders[provider.id] ?? .idle) == .idle {
                let animeId = state.animeId
                state.streamingProviders[provider.id] = .loading
                return .run {
                    await withTaskCancellation(id: FetchProviderCancellable.self) {
                        .fetchedProvider(
                            await animeClient.getEpisodes(animeId, provider)
                        )
                    }
                }
            } else if (state.streamingProviders[provider.id]?.finished == true) {
                return fetchLinkOptions(&state)
            }
        }

        return .none
    }

    private func fetchLinkOptions(_ state: inout State) -> EffectTask<Action> {
        if let provider = state.streamingProvider,
           let episode = state.episode {

            let preferredAudio = userDefaultsClient.get(.videoPlayerAudio)
            var preferredLink: EpisodeLink.ID? = episode.links
                .first { preferredAudio == $0.audio }?.id ?? (preferredAudio.isDub ? episode.links.first { $0.audio.isDub }?.id : nil)

            state.selectedLink = state.selectedLink ?? preferredLink ?? episode.links.first?.id

            if let link = state.link {
                return .run {
                    await withTaskCancellation(
                        id: FetchSourceOptionsCancellable.self,
                        cancelInFlight: true
                    ) {
                        await .fetchedSources(
                            .init { try await animeClient.getSources(provider.name, link) }
                        )
                    }
                }
            }
        }

        return .none
    }
}

