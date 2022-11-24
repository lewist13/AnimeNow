////  ModalOverlayView.swift
//  Anime Now! (iOS)
//
//  Created by ErrorErrorError on 11/20/22.
//  
//

import SwiftUI
import ComposableArchitecture

struct ModalOverlayView: View {
    let store: StoreOf<ModalOverlayReducer>

    var body: some View {
        WithViewStore(store.stateless) { viewStore in
            ModalCardView(
                onDismiss: { viewStore.send(.onClose) }
            ) {
                SwitchStore(store) {
                    CaseLet(
                        state: /ModalOverlayReducer.State.addNewCollection,
                        action: ModalOverlayReducer.Action.addNewCollection
                    ) {
                        AddNewCollectionView(store: $0)
                    }
                }
            }
        }
    }
}

struct ModalOverlayView_Previews: PreviewProvider {
    static var previews: some View {
        ModalOverlayView(
            store: .init(
                initialState: .addNewCollection(.init(namesUsed: [])),
                reducer: ModalOverlayReducer()
            )
        )
    }
}
