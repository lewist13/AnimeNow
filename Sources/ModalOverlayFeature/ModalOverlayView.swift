//
//  ModalOverlayView.swift
//  Anime Now!
//
//  Created by ErrorErrorError on 11/20/22.
//  
//

import SwiftUI
import ViewComponents
import NewCollectionFeature
import EditCollectionFeature
import DownloadOptionsFeature
import ComposableArchitecture

public struct ModalOverlayView: View {
    let store: StoreOf<ModalOverlayReducer>

    public init(store: StoreOf<ModalOverlayReducer>) {
        self.store = store
    }

    public var body: some View {
        ModalCardView(
            onDismiss: { ViewStore(store).send(.onClose) }
        ) {
            SwitchStore(store) {
                CaseLet(
                    state: /ModalOverlayReducer.State.addNewCollection,
                    action: ModalOverlayReducer.Action.addNewCollection,
                    then: NewCollectionView.init
                )

                CaseLet(
                    state: /ModalOverlayReducer.State.downloadOptions,
                    action: ModalOverlayReducer.Action.downloadOptions,
                    then: DownloadOptionsView.init
                )

                CaseLet(
                    state: /ModalOverlayReducer.State.editCollection,
                    action: ModalOverlayReducer.Action.editCollection,
                    then: EditCollectionView.init
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
