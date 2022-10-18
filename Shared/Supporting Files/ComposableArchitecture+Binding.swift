//
//  ComposableArchitecture+Binding.swift
//  Anime Now!
//
//  Created by ErrorErrorError on 9/26/22.
//

import SwiftUI
import ComposableArchitecture

public extension ViewStore {
  func binding<ParentState, Value>(
    _ parentKeyPath: WritableKeyPath<ParentState, BindableState<Value>>,
    as keyPath: KeyPath<State, Value>
  ) -> Binding<Value> where Action: BindableAction, Action.State == ParentState, Value: Equatable {
    binding(
      get: { $0[keyPath: keyPath] },
      send: { .binding(.set(parentKeyPath, $0)) }
    )
  }
}
