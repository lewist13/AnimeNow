//
//  SidebarEpisodesCore.swift
//  Anime Now! (iOS)
//
//  Created by Erik Bautista on 9/22/22.
//

import Foundation
import ComposableArchitecture

enum SidebarEpisodesCore {
    struct State: Equatable {
        let episodes: IdentifiedArrayOf<Episode>
        var selectedId: Episode.ID
    }

    enum Action: Equatable {
        case aboutToChangeEpisode(to: Episode.ID)
        case selected(id: Episode.ID)
    }

    struct Environment {
        let mainQueue: AnySchedulerOf<DispatchQueue>
        let animeClient: AnimeClient
    }

    static let reducer = Reducer<State, Action, Environment>.init { state, action, env in
        switch action {
        case .aboutToChangeEpisode(let episode):
            return .init(value: .selected(id: episode))
        case let .selected(id):
            state.selectedId = id
        }
        return .none
    }
}

extension SidebarEpisodesCore.State {
    var episode: Episode? {
        episodes[id: selectedId]
    }

    var nextEpisode: Episode? {
        if let currentInx = episodes.index(id: selectedId), currentInx + 1 < episodes.count {
            return episodes[currentInx + 1]
        }
        return nil
    }
}
