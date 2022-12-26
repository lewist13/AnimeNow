//  LifecycleReducer.swift
//  Anime Now!
//
//  Created by ErrorErrorError on 11/24/22.
//  
//

import ComposableArchitecture

struct LifecycleReducer<Wrapped: ReducerProtocol>: ReducerProtocol {
  enum Action {
    case onAppear
    case onDisappear
    case wrapped(Wrapped.Action)
  }

  let wrapped: Wrapped
  let onAppear: EffectTask<Wrapped.Action>
  let onDisappear: EffectTask<Never>

  var body: some ReducerProtocol<Wrapped.State?, Action> {
    Reduce { state, lifecycleAction in
      switch lifecycleAction {
      case .onAppear:
        return onAppear.map(Action.wrapped)

      case .onDisappear:
        return onDisappear.fireAndForget()

      case .wrapped:
        return .none
      }
    }
    .ifLet(\.self, action: /Action.wrapped) {
      self.wrapped
    }
  }
}

extension LifecycleReducer.Action: Equatable where Wrapped.Action: Equatable {}

extension ReducerProtocol {
  func lifecycle(
    onAppear: EffectTask<Action>,
    onDisappear: EffectTask<Never> = .none
  ) -> LifecycleReducer<Self> {
    LifecycleReducer(wrapped: self, onAppear: onAppear, onDisappear: onDisappear)
  }
}
