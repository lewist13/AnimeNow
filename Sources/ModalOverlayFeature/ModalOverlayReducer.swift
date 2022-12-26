//  ModalOverlayReducer.swift
//  Anime Now!
//
//  Created by ErrorErrorError on 11/20/22.
//

import Foundation
import NewCollectionFeature
import EditCollectionFeature
import DownloadOptionsFeature
import ComposableArchitecture

public struct ModalOverlayReducer: ReducerProtocol {
    public enum State: Equatable {
        case addNewCollection(NewCollectionReducer.State)
        case downloadOptions(DownloadOptionsReducer.State)
        case editCollection(EditCollectionReducer.State)
    }

    public enum Action: Equatable {
        case addNewCollection(NewCollectionReducer.Action)
        case downloadOptions(DownloadOptionsReducer.Action)
        case editCollection(EditCollectionReducer.Action)
        case onClose
    }
    
    public init() { }

    public var body: some ReducerProtocol<State, Action> {
        Reduce(self.core)
            .ifCaseLet(/State.addNewCollection, action: /Action.addNewCollection) {
                NewCollectionReducer()
            }
            .ifCaseLet(/State.downloadOptions, action: /Action.downloadOptions) {
                DownloadOptionsReducer()
            }
            .ifCaseLet(/State.editCollection, action: /Action.editCollection) {
                EditCollectionReducer()
            }
    }

    func core(_ state: inout State, _ action: Action) -> EffectTask<Action> {
        return .none
    }
}
