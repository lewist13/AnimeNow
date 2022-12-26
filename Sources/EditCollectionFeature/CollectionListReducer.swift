//
//  EditCollectionReducer.swift
//  Anime Now! (iOS)
//
//  Created by ErrorErrorError on 11/17/22.
//  
//

import Foundation
import SharedModels
import ComposableArchitecture

public struct EditCollectionReducer: ReducerProtocol {
    public init() { }

    public struct State: Equatable {
        public let animeId: AnyAnimeRepresentable.ID
        public var collections = Set<CollectionStore>()

        public init(
            animeId: AnyAnimeRepresentable.ID,
            collections: Set<CollectionStore> = Set<CollectionStore>()
        ) {
            self.animeId = animeId
            self.collections = collections
        }
    }

    public enum Action: Equatable {
        case onAppear
        case collectionSelectedToggle(CollectionStore.ID)
        case onCloseTapped
    }

    public var body: some ReducerProtocol<State, Action> {
        Reduce(self.core)
    }
}

extension EditCollectionReducer.State {
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

extension EditCollectionReducer {
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
