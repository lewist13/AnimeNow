//  ModalOverlayView.swift
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
        ModalCardView(
            onDismiss: { ViewStore(store).send(.onClose) }
        ) {
            SwitchStore(store) {
                CaseLet(
                    state: /ModalOverlayReducer.State.addNewCollection,
                    action: ModalOverlayReducer.Action.addNewCollection,
                    then: AddNewCollectionView.init
                )

                CaseLet(
                    state: /ModalOverlayReducer.State.downloadOptions,
                    action: ModalOverlayReducer.Action.downloadOptions,
                    then: DownloadOptionsView.init
                )

                CaseLet(
                    state: /ModalOverlayReducer.State.collectionList,
                    action: ModalOverlayReducer.Action.collectionList,
                    then: CollectionListView.init
                )
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
