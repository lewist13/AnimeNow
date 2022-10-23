//
//  AnimeNowApp.swift
//  Shared
//
//  Created by ErrorErrorError on 9/2/22.
//

import SwiftUI

@main
struct AnimeNowApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            AppView(
                store: .init(
                    initialState: .init(),
                    reducer: AppReducer()
                )
            )
        }
        .windowStyle(.hiddenTitleBar)
        .windowToolbarStyle(.expanded)
    }
}
