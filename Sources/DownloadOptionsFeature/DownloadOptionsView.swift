//  DownloadOptionsView.swift
//  Anime Now!
//
//  Created by ErrorErrorError on 11/24/22.
//  

import SwiftUI
import Utilities
import SharedModels
import SettingsFeature
import AnimeStreamLogic
import ComposableArchitecture

public struct DownloadOptionsView: View {
    let store: StoreOf<DownloadOptionsReducer>

    public init(store: StoreOf<DownloadOptionsReducer>) {
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
                    observe: { AnimeStreamViewState($0.stream) }
                ) { viewState in
                    Group {
                        SettingsRowExpandableListView(items: viewState.availableProviders.items) {
                            SettingsRowView(
                                name: "Provider",
                                text: viewState.availableProviders.item?.name ?? (viewState.availableProviders.items.count > 0 ? "Not Selected" : "Unavailable")
                            )
                            .multiSelection(viewState.availableProviders.items.count > 1)
                        } itemView: { item in
                            Text(item.name)
                        } selectedItem: {
                            viewState.send(.animeStream(.selectProvider($0)))
                        }

                        SettingsRowExpandableListView(items: viewState.links.items) {
                            SettingsRowView(
                                name: "Audio",
                                text: viewState.links.item?.audioDescription ?? (viewState.links.items.count > 0 ? "Not Selected" : "Unavailable")
                            )
                            .loading(viewState.loadingLink)
                            .multiSelection(viewState.links.items.count > 1)
                        } itemView: { item in
                            Text(item.audioDescription)
                        } selectedItem: {
                            viewState.send(.animeStream(.selectLink($0)))
                        }

                        SettingsRowExpandableListView(items: viewState.sources.items) {
                            SettingsRowView(
                                name: "Quality",
                                text: viewState.sources.item?.quality.description ?? (viewState.sources.items.count > 0 ? "Not Selected" : "Unavailable")
                            )
                            .loading(
                                viewState.loadingLink ?
                                    true : viewState.links.items.count > 0 ?
                                    viewState.loadingSource : false
                            )
                            .multiSelection(viewState.sources.items.count > 1)
                        } itemView: { item in
                            Text(item.quality.description)
                        } selectedItem: {
                            viewState.send(.animeStream(.selectSource($0)))
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
                    episodeId: 1,
                    availableProviders: .init(
                        items: [
                            .init(name: "Gogoanime")
                        ]
                    )
                ),
                reducer: DownloadOptionsReducer()
            )
        )
        .padding(24)
        .background(Color(white: 0.12))
        .preferredColorScheme(.dark)
    }
}
