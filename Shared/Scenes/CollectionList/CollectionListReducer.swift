////  CollectionPromptReducer.swift
//  Anime Now! (iOS)
//
//  Created by ErrorErrorError on 11/17/22.
//  
//

import Foundation
import ComposableArchitecture

struct CollectionListReducer: ReducerProtocol {
    struct State: Equatable {
        let animeId: AnyAnimeRepresentable.ID
        var collections = Set<CollectionStore>()
    }

    enum Action: Equatable {
        case onAppear
        case collectionSelectedToggle(CollectionStore.ID)
        case onCloseTapped
    }

    var body: some ReducerProtocol<State, Action> {
        Reduce(self.core)
    }
}

extension CollectionListReducer.State {
    var sortedCollections: [CollectionStore] {
        collections.sorted { one, two in
            let oneHasAnime = one.animes[id: animeId] != nil
            let twoHasAnime = two.animes[id: animeId] != nil

            if oneHasAnime && twoHasAnime {
                return one.title.value < two.title.value
            } else if oneHasAnime {
                return true
            } else if twoHasAnime {
                return false
            } else {
                return one.title.value < two.title.value
            }
        }
    }
}

extension CollectionListReducer {
    func core(into state: inout State, action: Action) -> EffectTask<Action> {
        switch action {
        case .onAppear:
            break

        case .collectionSelectedToggle:
            break

        case .onCloseTapped:
            break
        }
        return .none
    }
}
