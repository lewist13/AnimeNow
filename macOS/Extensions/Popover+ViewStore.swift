////  Popover+ViewStore.swift
//  Anime Now! (macOS)
//
//  Created by ErrorErrorError on 10/31/22.
//  
//

import SwiftUI
import ComposableArchitecture

extension View {
    func popoverStore<State, Action, Content: View>(
        store: Store<State?, Action>,
        onDismiss: @escaping () -> Void = { },
        destination: @escaping (Store<State, Action>) -> Content
    ) -> some View {
        WithViewStore(
            store,
            observe: { $0 != nil }
        ) { viewStore in
            self.popover(
                isPresented: .init(
                    get: { viewStore.state },
                    set: { $0 ? () : onDismiss() }
                )
            ) {
                IfLetStore(
                    store
                ) { store in
                    destination(store)
                }
            }
        }
    }
}
