//
//  AppDelegate.swift
//  Anime Now! (macOS)
//
//  Created by ErrorErrorError on 10/22/22.
//

import AppKit
import AppFeature
import Foundation
import ComposableArchitecture

class AppDelegate: NSObject, NSApplicationDelegate {
    let store = Store(
      initialState: AppReducer.State(),
      reducer: AppReducer()
    )

    func applicationDidFinishLaunching(_ notification: Notification) {
        ViewStore(store).send(.appDelegate(.appDidFinishLaunching))
    }

    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        let viewStore = ViewStore(store)

        if viewStore.hasPendingChanges {
            viewStore.send(.appDelegate(.appWillTerminate))
            return .terminateLater
        }

        return .terminateNow
    }
}
