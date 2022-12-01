//  DownloadOptionsView.swift
//  Anime Now! (iOS)
//
//  Created by ErrorErrorError on 11/24/22.
//  

import SwiftUI
import ComposableArchitecture

struct VideoOptionsViewState: Equatable {
    let selectedProvider: Provider.ID?
    let selectedSource: Source.ID?

    let isLoadingProviders: Bool
    let isLoadingSources: Bool

    var isLoading: Bool {
        isLoadingProviders || isLoadingSources
    }

    private let providers: [Provider]?
    private let sources: [Source]?

    var provider: Provider? {
        if let selectedProvider = selectedProvider {
            return providers?[id: selectedProvider]
        }
        return nil
    }

    var selectableProviders: [Provider] {
        if let providers = providers {
            var returnVal = [Provider]()

            if let selectedProvider = self.provider {
                returnVal.append(selectedProvider)
            }

            for provider in providers {
                if !returnVal.contains(where: { $0.description == provider.description }) {
                    returnVal.append(provider)
                }
            }

            return returnVal
        }

        return []
    }

    struct IdentifiedQuality: Equatable, Identifiable, CustomStringConvertible {
        let id: Source.ID
        let quality: Source.Quality

        init(_ source: Source) {
            self.id = source.id
            self.quality = source.quality
        }

        var description: String {
            quality.description
        }
    }

    var selectableQualities: [IdentifiedQuality]? {
        if let sources = sources {
            return sources.map(IdentifiedQuality.init)
        }
        return nil
    }

    var quality: IdentifiedQuality? {
        if let selectedSource = selectedSource {
            return selectableQualities?[id: selectedSource]
        }
        return nil
    }

    struct IdentifiedAudio: Equatable, Identifiable, CustomStringConvertible {
        let id: Provider.ID
        let language: String

        init(_ provider: Provider) {
            self.id = provider.id
            self.language = (provider.dub ?? false) ? "English" : "Japanese"
        }

        var description: String {
            language
        }
    }

    var selectableAudio: [IdentifiedAudio]? {
        if let providers = providers, let provider = provider {
            let filtered = providers.filter { $0.description == provider.description }
            return filtered.map(IdentifiedAudio.init)
        }
        return nil
    }

    var audio: IdentifiedAudio? {
        if let provider = provider, let languages = selectableAudio {
            return languages[id: provider.id]
        }
        return nil
    }

    init(_ state: AnimePlayerReducer.State) {
        self.isLoadingProviders = !state.episodes.finished
        self.isLoadingSources =  !state.sourcesOptions.finished
        self.providers = state.episode?.providers
        self.sources = state.sourcesOptions.value?.sources
        self.selectedProvider = state.selectedProvider
        self.selectedSource = state.selectedSource
    }

    init(_ state: DownloadOptionsReducer.State) {
        self.isLoadingProviders = !state.providers.finished
        self.isLoadingSources = !state.sources.finished
        self.providers = state.providers.value
        self.sources = state.sources.value
        self.selectedProvider = state.providerSelected
        self.selectedSource = state.sourceSelected
    }
}

struct DownloadOptionsView: View {
    let store: StoreOf<DownloadOptionsReducer>

    var body: some View {
        LazyVStack(
            alignment: .center,
            spacing: 24
        ) {
            VStack(spacing: 8) {
                Text("Download Options")
                    .font(.title.bold())
                    .multilineTextAlignment(.center)

                Text("You can select which options you want to download for this episode.")
                    .font(.callout)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.gray)
            }

            LazyVStack(spacing: 8) {
                WithViewStore(
                    store,
                    observe: VideoOptionsViewState.init
                ) { viewState in
                    SettingsSelectableListView(items: viewState.selectableProviders) {
                        .init(
                            name: "Provider",
                            selected: viewState.isLoadingProviders ? nil : viewState.provider?.description,
                            loading: viewState.isLoadingProviders
                        )
                    } itemView: { item in
                        Text(item.description)
                    } selectedItem: {
                        viewState.send(.selectProvider($0))
                    }

                    SettingsSelectableListView(items: viewState.selectableAudio ?? []) {
                        .init(
                            name: "Audio",
                            selected: viewState.isLoadingProviders ? nil : viewState.audio?.language,
                            loading: viewState.isLoadingProviders
                        )
                    } itemView: { item in
                        Text(item.description)
                    } selectedItem: {
                        viewState.send(.selectProvider($0))
                    }

                    SettingsSelectableListView(items: viewState.selectableQualities ?? []) {
                        .init(
                            name: "Quality",
                            selected: viewState.isLoadingSources ? nil : viewState.quality?.description,
                            loading: viewState.isLoadingSources
                        )
                    } itemView: { item in
                        Text(item.description)
                    } selectedItem: {
                        viewState.send(.selectSource($0))
                    }
                }
            }

            WithViewStore(
                store,
                observe: \.canDownload
            ) { viewStore in
                Button {
                    viewStore.send(.downloadClicked)
                } label: {
                    Text("Download")
                        .font(.body.bold())
                        .foregroundColor(Color.black)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(viewStore.state ? Color.white : Color.gray)
                        .cornerRadius(12)
                }
                .buttonStyle(.plain)
                .disabled(!viewStore.state)
            }
        }
        .onAppear {
            ViewStore(store).send(.onAppear)
        }
    }
}

struct DownloadOptionsView_Previews: PreviewProvider {
    static var previews: some View {
        DownloadOptionsView(
            store: .init(
                initialState: .init(
                    anime: Anime.attackOnTitan,
                    episode: Episode.placeholder
                ),
                reducer: EmptyReducer()
            )
        )
        .padding(24)
        .background(Color(white: 0.12))
        .preferredColorScheme(.dark)
    }
}
