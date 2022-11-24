//  AddNewCollectionReducer.swift
//  Anime Now! (iOS)
//
//  Created by ErrorErrorError on 11/19/22.
//  

import SwiftORM
import ComposableArchitecture

struct AddNewCollectionReducer: ReducerProtocol {
    struct State: Equatable {
        @BindableState var title = ""
        var namesUsed: Set<String> = []
    }

    enum Action: BindableAction, Equatable {
        case onAppear
        case fetchedTitles([String])
        case saveTitle
        case binding(BindingAction<State>)
    }

    var body: some ReducerProtocol<State, Action> {
        BindingReducer()
        Reduce(self.core)
    }

    @Dependency(\.repositoryClient) var repositoryClient

    func core(_ state: inout State, _ action: Action) -> EffectTask<Action> {
        switch action {
        case .onAppear:
            return .run { send in
                let titles: [CollectionStore] = try await repositoryClient.fetch(CollectionStore.all)
                await send(.fetchedTitles(titles.map(\.title.value)))
            }
        case .fetchedTitles(let titles):
            state.namesUsed = .init(titles)

        case .saveTitle:
            let title = state.title
            return .run { send in
                let collection = CollectionStore(title: .custom(title))
                try await repositoryClient.insert(collection)
            }

        default:
            break
        }
        return .none
    }
}

extension AddNewCollectionReducer.State {
    var canSave: Bool {
        let formatTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)

        return formatTitle.count > 0 && !namesUsed
            .map({ $0.localizedLowercase.trimmingCharacters(in: .whitespacesAndNewlines) })
            .contains(formatTitle.localizedLowercase.trimmingCharacters(in: .whitespacesAndNewlines))
    }
}
