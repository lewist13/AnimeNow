//
//  Reducer+Relay.swift
//  Anime Now!
//
//  Created by ErrorErrorError on 10/5/22.
// From https://github.com/pointfreeco/swift-composable-architecture/discussions/851#discussioncomment-1469781

import Foundation
import Combine
import ComposableArchitecture

public extension Reducer {
    func relay(
        actionPredicate: @escaping (Action) -> Bool,
        destination: PassthroughSubject<Action, Never>
    ) -> Self {
        combined(with: .init { _, action, _ in
            if actionPredicate(action) {
                return .fireAndForget {
                    destination.send(action)
                }
            }
            return .none
        }
        )
    }
}
