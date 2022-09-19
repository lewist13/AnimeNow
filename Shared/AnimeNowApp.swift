//
//  AnimeNowApp.swift
//  Shared
//
//  Created by Erik Bautista on 9/2/22.
//

import SwiftUI

@main
struct AnimeNowApp: App {
    var body: some Scene {
        #if os(iOS)
        WindowGroup {
            ContentView(
                store: .init(
                    initialState: .init(),
                    reducer: ContentCore.reducer,
                    environment: .live
                )
            )
            .preferredColorScheme(.dark)
        }
        #elseif os(macOS)
        WindowGroup {
            ContentView()
        }
        #endif
    }
}
