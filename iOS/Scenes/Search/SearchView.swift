//
//  SearchView.swift
//  Anime Now!
//
//  Created Erik Bautista on 9/4/22.
//  Copyright © 2022. All rights reserved.
//

import ComposableArchitecture
import SwiftUI

struct SearchView: View {
    let store: Store<SearchCore.State, SearchCore.Action>

    var body: some View {
        Text("Hello world!")
    }
}

struct SearchView_Previews: PreviewProvider {
    static var previews: some View {
        SearchView(
            store: .init(
                initialState: .init(),
                reducer: SearchCore.reducer,
                environment: .init(
                    animeList: .mock
                )
            )
        )
    }
}
