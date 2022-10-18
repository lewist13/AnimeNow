//
//  AnimeNowApp.swift
//  Shared
//
//  Created by Erik Bautista on 9/2/22.
//

import SwiftUI

#if os(macOS)
@main
struct AnimeNowApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView(
                store: .init(
                    initialState: .init(),
                    reducer: ContentCore.reducer,
                    environment: .live
                )
            )
        }
        .windowStyle(.hiddenTitleBar)
        .windowToolbarStyle(.expanded)
    }
}
#endif
