//
//  SettingsView+iOS.swift
//  Anime Now!
//
//  Created by ErrorErrorError on 12/15/22.  
//

import SwiftUI
import DiscordClient
import ViewComponents
import ComposableArchitecture

public struct SettingsView: View {
    let store: StoreOf<SettingsReducer>

    public init(store: StoreOf<SettingsReducer>) {
        self.store = store
    }

    public var body: some View {
        WithViewStore(
            store,
            observe: { $0 }
        ) { viewStore in
            StackNavigation(title: "Settings") {
                ScrollView {
                    LazyVStack(spacing: 24) {
                        SettingsGroupView(title: "General") {
                            SettingsRowView.listSelection(
                                name: "Preferred Provider",
                                selectable: viewStore.selectableAnimeProviders,
                                onSelectedItem: {
                                    viewStore.send(
                                        .binding(
                                            .set(\.$userSettings.preferredProvider, $0)
                                        )
                                    )
                                },
                                itemView: { item in
                                    Text(item.description)
                                }
                            )

                            SettingsRowView(
                                name: "About"
                            ) {

                            }
                        }

                        if viewStore.supportsDiscord {
                            SettingsGroupView(title: "Discord") {
                                SettingsRowView(
                                    name: "Enable",
                                    active: viewStore.binding(\.$userSettings.discordEnabled)
                                )

                                if viewStore.userSettings.discordEnabled {
                                    SettingsRowView(
                                        name: "Status",
                                        text: viewStore.discordStatus.rawValue
                                    )
                                }
                            }
                            .animation(
                                .easeInOut(
                                    duration: 0.12
                                ),
                                value: viewStore.state
                            )
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .onAppear {
                viewStore.send(.onAppear)
            }
        }
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView(
            store: .init(
                initialState: .init(),
                reducer: EmptyReducer()
            )
        )
        .preferredColorScheme(.dark)
    }
}
