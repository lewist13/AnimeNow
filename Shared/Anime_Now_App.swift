//
//  Anime_Now_App.swift
//  Shared
//
//  Created by Erik Bautista on 9/2/22.
//

import SwiftUI

@main
struct Anime_Now_App: App {
    var body: some Scene {
        #if os(iOS)
        WindowGroup {
            ContentView(
                store: .init(
                    initialState: .init(),
                    reducer: ContentCore.reducer,
                    environment: .init(
                        listClient: .kitsu
                    )
                )
            )
            .preferredColorScheme(.dark)
        }
        #else
        WindowGroup {
            ContentView()
        }
        #endif
    }
}
