//
//  ContentView.swift
//  Anime Now! (macOS)
//
//  Created by Erik Bautista on 9/3/22.
//

import SwiftUI
import ComposableArchitecture

struct ContentView: View {
    let store: Store<ContentCore.State, ContentCore.Action>

    var body: some View {
        Text("Hello, macOS!")
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(
            store: .init(
                initialState: .init(),
                reducer: ContentCore.reducer,
                environment: .init(
                    animeClient: .mock,
                    mainQueue: .main,
                    mainRunLoop: .main,
                    repositoryClient: RepositoryClientMock.shared,
                    userDefaultsClient: .mock
                )
            )
        )
    }
}
