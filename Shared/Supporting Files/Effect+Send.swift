//
//  Effect+Send.swift
//  Anime Now!
//
//  Created by ErrorErrorError on 10/22/22.
//

import Foundation
import ComposableArchitecture

extension EffectTask where Failure == Never {
    public static func action(
      priority: TaskPriority? = nil,
      _ action: Action
    ) -> Self {
        self.run(priority: priority) { await $0(action) }
    }

    public static func run(_ operation: @escaping @Sendable () async throws -> Void) -> Self {
      self.run { _ in try await operation() }
    }

    public static func run(_ operation: @escaping @Sendable () async throws -> Action) -> Self {
      self.run { try await $0(operation()) }
    }
}
