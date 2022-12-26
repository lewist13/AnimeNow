//  DownloadOptionsView.swift
//  Anime Now!
//
//  Created by ErrorErrorError on 11/24/22.
//  

import SwiftUI
import SharedModels
import SettingsFeature
import ComposableArchitecture

public struct VideoOptionsViewState: Equatable {
    public let selectedProvider: Provider.ID?
    public let selectedSource: Source.ID?

    public let isLoadingProviders: Bool
    public let isLoadingSources: Bool

    private let providers: [Provider]
    private let sources: [Source]

    public var isLoading: Bool {
        isLoadingProviders || isLoadingSources
    }

    public var provider: Provider? {
        if let selectedProvider = selectedProvider {
            return providers[id: selectedProvider]
        }
        return nil
    }

    public var selectableProviders: [Provider] {
        var returnVal = [Provider]()

        if let selectedProvider = self.provider {
            returnVal.append(selectedProvider)
        }
        
        for provider in providers {
            if !returnVal.contains(
                where: { $0.description == provider.description }
            ) {
                returnVal.append(provider)
            }
        }
        
        return returnVal
    }

    public struct IdentifiedQuality: Equatable, Identifiable, CustomStringConvertible {
        public let id: Source.ID
        public let quality: Source.Quality

        init(_ source: Source) {
            self.id = source.id
            self.quality = source.quality
        }

        public var description: String {
            quality.description
        }
    }

    public var selectableQualities: [IdentifiedQuality] {
        return sources.map(IdentifiedQuality.init)
    }

    public var quality: IdentifiedQuality? {
        if let selectedSource = selectedSource {
            return selectableQualities[id: selectedSource]
        }
        return nil
    }

    public struct IdentifiedAudio: Equatable, Identifiable, CustomStringConvertible {
        public let id: Provider.ID
        public let language: String

        public init(_ provider: Provider) {
            self.id = provider.id
            self.language = (provider.dub ?? false) ? "English" : "Japanese"
        }

        public var description: String {
            language
        }
    }

    public var selectableAudio: [IdentifiedAudio] {
        if let provider = provider {
            return providers.filter {
                $0.description == provider.description
            }
            .map(IdentifiedAudio.init)
        }
        return []
    }

    public var audio: IdentifiedAudio? {
        if let provider = provider {
            return selectableAudio[id: provider.id]
        }
        return nil
    }

    public init(
        isLoadingProviders: Bool,
        isLoadingSources: Bool,
        providers: [Provider],
        sources: [Source],
        selectedProvider: Provider.ID? = nil,
        selectedSource: Source.ID? = nil
    ) {
        self.isLoadingProviders = isLoadingProviders
        self.isLoadingSources = isLoadingSources
        self.providers = providers
        self.sources = sources
        self.selectedProvider = selectedProvider
        self.selectedSource = selectedSource
    }
}

extension VideoOptionsViewState {
    init(_ state: DownloadOptionsReducer.State) {
        self.init(
            isLoadingProviders: !state.providers.finished,
            isLoadingSources: !state.sources.finished,
            providers: state.providers.value ?? [],
            sources: state.sources.value ?? [],
            selectedProvider: state.providerSelected,
            selectedSource: state.sourceSelected
        )
    }
}

public struct DownloadOptionsView: View {
    let store: StoreOf<DownloadOptionsReducer>

    public init(
        store: StoreOf<DownloadOptionsReducer>
    ) {
        self.store = store
    }

    public var body: some View {
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
                    Group {
                        SettingsRowExpandableListView(items: viewState.selectableProviders) {
                            SettingsRowView(
                                name: "Provider",
                                text: viewState.provider?.description ?? ""
                            )
                            .loading(viewState.isLoadingProviders)
                            .multiSelection(viewState.selectableProviders.count > 1)
                        } itemView: { item in
                            Text(item.description)
                        } selectedItem: {
                            viewState.send(.selectProvider($0))
                        }

                        SettingsRowExpandableListView(items: viewState.selectableAudio) {
                            SettingsRowView(
                                name: "Audio",
                                text: viewState.audio?.language ?? ""
                            )
                            .loading(viewState.isLoadingProviders)
                            .multiSelection(viewState.selectableAudio.count > 1)
                        } itemView: { item in
                            Text(item.description)
                        } selectedItem: {
                            viewState.send(.selectProvider($0))
                        }

                        SettingsRowExpandableListView(items: viewState.selectableQualities) {
                            SettingsRowView(
                                name: "Quality",
                                text: viewState.quality?.description ?? ""
                            )
                            .loading(viewState.isLoadingSources)
                            .multiSelection(viewState.selectableQualities.count > 1)
                        } itemView: { item in
                            Text(item.description)
                        } selectedItem: {
                            viewState.send(.selectSource($0))
                        }
                    }
                    .animation(.easeInOut, value: viewState.state)
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
                .animation(.easeInOut, value: viewStore.state)
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
