//
//  SidebarSourcesView.swift
//  Anime Now! (iOS)
//
//  Created by Erik Bautista on 9/22/22.
//

import SwiftUI
import ComposableArchitecture

struct SidebarSourcesView: View {
    let store: Store<SidebarSourcesCore.State, SidebarSourcesCore.Action>

    var body: some View {
        Text(/*@START_MENU_TOKEN@*/"Hello, World!"/*@END_MENU_TOKEN@*/)
    }
}

struct SidebarSourcesView_Previews: PreviewProvider {
    static var previews: some View {
        SidebarSourcesView(
            store: .init(
                initialState: .init(),
                reducer: .empty,
                environment: ()
            )
        )
    }
}
