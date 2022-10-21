//
//  DownloadsCore.swift
//  Anime Now!
//
//  Created by ErrorErrorError on 9/25/22.
//  Copyright © 2022. All rights reserved.
//

import ComposableArchitecture

enum DownloadsCore {
    struct State: Equatable {
        
    }

    enum Action: Equatable {
        case onAppear
    }

    struct Environment {

    }
}

extension DownloadsCore {
    static var reducer: Reducer<DownloadsCore.State, DownloadsCore.Action, DownloadsCore.Environment> {
        .init { state, action, environment in
            return .none
        }
    }
}
