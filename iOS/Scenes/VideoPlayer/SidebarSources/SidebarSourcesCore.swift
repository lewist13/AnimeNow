//
//  SidebarSourcesCore.swift
//  Anime Now! (iOS)
//
//  Created by Erik Bautista on 9/22/22.
//

import Foundation
import IdentifiedCollections
import ComposableArchitecture
import SwiftUI

enum SidebarSourcesCore {
    typealias LoadableSources = LoadableState<IdentifiedArrayOf<Source>>

    struct State: Equatable {
        var sources: LoadableSources = .preparing
        var selectedSourceId: Source.ID?
    }

    enum Action: Equatable {
        case selected(id: Source.ID)
        case fetchSources(episodeId: Episode.ID)
        case fetchedSources(Result<[Source], API.Error>)
    }

    struct Environment {
        let mainQueue: AnySchedulerOf<DispatchQueue>
        let animeClient: AnimeClient
    }

    static let reducer = Reducer<State, Action, Environment>.init { state, action, env in
        switch action {
        case let .selected(id):
            state.selectedSourceId = id
        case let .fetchSources(episodeId):
            state.sources = .loading
            return env.animeClient.getSources(episodeId)
                .receive(on: env.mainQueue)
                .catchToEffect()
                .map(Action.fetchedSources)
        case let .fetchedSources(.success(sources)):
            state.sources = .success(.init(uniqueElements: sources))
            state.selectedSourceId = sources.first?.id
        case .fetchedSources(.failure):
            state.sources = .failed
            state.selectedSourceId = nil
        }
        return .none
    }
}

extension SidebarSourcesCore.State {
    var source: Source? {
        if case let .success(sources) = sources, let selected = selectedSourceId {
            return sources[id: selected] ?? sources.first
        }
        return nil
    }

    var sourceItems: IdentifiedArrayOf<Source> {
        if case let .success(sources) = sources {
            return sources
        }
        return .init()
    }
}
