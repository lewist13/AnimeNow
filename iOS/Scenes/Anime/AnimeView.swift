//
//  AnimeView.swift
//  Anime Now!
//
//  Created Erik Bautista on 9/6/22.
//  Copyright © 2022. All rights reserved.
//

import ComposableArchitecture
import SwiftUI

struct AnimeView: View {
    let store: Store<AnimeCore.State, AnimeCore.Action>

    var body: some View {
        Text("Hello world!")
    }
}

struct AnimeView_Previews: PreviewProvider {
    static var previews: some View {
        AnimeView(
            store: .init(
                initialState: .narutoShippuden,
                reducer: AnimeCore.reducer,
                environment: .init()
            )
        )
    }
}
