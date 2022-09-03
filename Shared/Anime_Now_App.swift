//
//  Anime_Now_App.swift
//  Shared
//
//  Created by Erik Bautista on 9/2/22.
//

import SwiftUI

@main
struct Anime_Now_App: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
