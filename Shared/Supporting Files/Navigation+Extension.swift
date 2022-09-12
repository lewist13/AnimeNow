//
//  Navigation+Extension.swift
//  Anime Now!
//
//  Created by Erik Bautista on 9/9/22.
//

import Foundation
import ComposableArchitecture
import SwiftUI


extension View {
    func fullScreenStore<State, Action, Content: View>(
        store: Store<State?, Action>,
        onDismiss: @escaping () -> Void,
        destination: @escaping (Store<State, Action>) -> Content
    ) -> some View {
        WithViewStore(store.scope(state: { $0 != nil })) { viewStore in
            self.fullScreenCover(
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
