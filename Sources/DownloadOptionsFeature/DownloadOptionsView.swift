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

            ScrollView {
                WithViewStore(
                    store,
                    observe: { AnimeStreamViewState($0.stream) }
                ) { viewState in
                    SettingsGroupView {
                        SettingsRowView.listSelection(
                            name: "Provider",
                            selectable: viewState.availableProviders
                        ) {
                            viewState.send(.animeStream(.selectProvider($0)))
                        } itemView: {
                            Text($0.name)
                        }

                        SettingsRowView.listSelection(
                            name: "Audio",
                            selectable: viewState.links,
                            loading: viewState.loadingLink
                        ) {
                            viewState.send(.animeStream(.selectLink($0)))
                        } itemView: {
                            Text($0.description)
                        }

                        SettingsRowView.listSelection(
                            name: "Quality",
                            selectable: viewState.sources,
                            loading: viewState.loadingLink || viewState.links.items.count > 0 && viewState.loadingSource
                        ) {
                            viewState.send(.animeStream(.selectSource($0)))
                        } itemView: {
                            Text($0.quality.description)
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
