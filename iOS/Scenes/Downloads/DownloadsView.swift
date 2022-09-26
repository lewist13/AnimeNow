//
//  DownloadsView.swift
//  Anime Now!
//
//  Created Erik Bautista on 9/25/22.
//  Copyright © 2022. All rights reserved.
//

import ComposableArchitecture
import SwiftUI

struct DownloadsView: View {
    let store: Store<DownloadsCore.State, DownloadsCore.Action>

    var body: some View {
        Text("Hello download!")
    }
}

struct DownloadsView_Previews: PreviewProvider {
    static var previews: some View {
        DownloadsView(
            store: .init(
                initialState: .init(),
                reducer: DownloadsCore.reducer,
                environment: .init()
            )
        )
    }
}
