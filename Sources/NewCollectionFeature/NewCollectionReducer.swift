//
//  NewCollectionReducer.swift
//  Anime Now! (iOS)
//
//  Created by ErrorErrorError on 11/19/22.
//  

import SharedModels
import DatabaseClient
import ComposableArchitecture

public struct NewCollectionReducer: ReducerProtocol {
    public init() { }

    public struct State: Equatable {
        @BindableState var title = ""
        var namesUsed: Set<String> = []

        public init(
            title: String = "",
            namesUsed: Set<String> = []
        ) {
            self.title = title
            self.namesUsed = namesUsed
        }
    }

    public enum Action: BindableAction, Equatable {
        case onAppear
        case fetchedTitles([String])
        case saveTitle
        case binding(BindingAction<State>)
    }

    public var body: some ReducerProtocol<State, Action> {
        BindingReducer()
        Reduce(self.core)
    }

    @Dependency(\.databaseClient) var databaseClient

    func core(_ state: inout State, _ action: Action) -> EffectTask<Action> {
        switch action {
        case .onAppear:
            return .run { send in
                let titles: [CollectionStore] = try await databaseClient.fetch(CollectionStore.all)
                await send(.fetchedTitles(titles.map(\.title.value)))
            }
        case .fetchedTitles(let titles):
            state.namesUsed = .init(titles)

        case .saveTitle:
            let title = state.title
            return .run { send in
                let collection = CollectionStore(title: .custom(title))
                try await databaseClient.insert(collection)
            }

        default:
            break
        }
        return .none
    }
}

extension NewCollectionReducer.State {
    var canSave: Bool {
        let formatTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)

        return formatTitle.count > 0 && !namesUsed
            .map({ $0.localizedLowercase.trimmingCharacters(in: .whitespacesAndNewlines) })
            .contains(formatTitle.localizedLowercase.trimmingCharacters(in: .whitespacesAndNewlines))
    }
}
