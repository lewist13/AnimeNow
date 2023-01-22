//
//  File.swift
//  
//
//  Created by ErrorErrorError on 1/7/23.
//  
//

import SwiftUI
import Utilities
import Foundation
import ComposableArchitecture

public struct LoadableView<T, Loaded: View, Failed: View, Loading: View, Idle: View>: View {
    let loadable: Loadable<T>
    let loadedView: (T) -> Loaded
    let failedView: () -> Failed
    let loadingView: () -> Loading
    let idleView: () -> Idle

    var asGroup = true

    public init(
        loadable: Loadable<T>,
        @ViewBuilder loadedView: @escaping (T) -> Loaded,
        @ViewBuilder failedView: @escaping () -> Failed,
        @ViewBuilder loadingView: @escaping () -> Loading,
        @ViewBuilder idleView: @escaping () -> Idle
    ) {
        self.loadable = loadable
        self.loadedView = loadedView
        self.failedView = failedView
        self.loadingView = loadingView
        self.idleView = idleView
    }

    public var body: some View {
        if asGroup {
            ZStack {
                buildViews()
            }
        } else {
            buildViews()
        }
    }

    @ViewBuilder
    private func buildViews() -> some View {
        switch loadable {
        case .idle:
            idleView()
        case .loading:
            loadingView()
        case .success(let t):
            loadedView(t)
        case .failed:
            failedView()
        }
    }
}

extension LoadableView {
    public func asGroup(_ group: Bool) -> Self {
        var view = self
        view.asGroup = group
        return view
    }
}

extension LoadableView where Loading == EmptyView, Failed == EmptyView, Idle == EmptyView {
    public init(
        loadable: Loadable<T>,
        @ViewBuilder loadedView: @escaping (T) -> Loaded
    ) {
        self.init(
            loadable: loadable,
            loadedView: loadedView,
            failedView: { EmptyView() },
            loadingView: { EmptyView() },
            idleView: { EmptyView() }
        )
    }
}

extension LoadableView where Loading == Idle {
    public init(
        loadable: Loadable<T>,
        @ViewBuilder loadedView: @escaping (T) -> Loaded,
        @ViewBuilder failedView: @escaping () -> Failed,
        @ViewBuilder waitingView: @escaping () -> Idle
    ) {
        self.init(
            loadable: loadable,
            loadedView: loadedView,
            failedView: failedView,
            loadingView: waitingView,
            idleView: waitingView
        )
    }
}

public struct LoadableStore<T: Equatable, Action, Loaded: View, Failed: View, Loading: View, Idle: View>: View {
    let store: Store<Loadable<T>, Action>
    let loadedView: (Store<T, Action>) -> Loaded
    let failedView: (Store<Error, Action>) -> Failed
    let loadingView: (Store<Void, Action>) -> Loading
    let idleView: (Store<Void, Action>) -> Idle

    public init(
        store: Store<Loadable<T>, Action>,
        @ViewBuilder loadedView: @escaping (Store<T, Action>) -> Loaded,
        @ViewBuilder failedView: @escaping (Store<Error, Action>) -> Failed,
        @ViewBuilder loadingView: @escaping (Store<Void, Action>) -> Loading,
        @ViewBuilder idleView: @escaping (Store<Void, Action>) -> Idle
    ) {
        self.store = store
        self.loadedView = loadedView
        self.failedView = failedView
        self.loadingView = loadingView
        self.idleView = idleView
    }

    public var body: some View {
        SwitchStore(store) {
            CaseLet(state: /Loadable<T>.success, then: loadedView)
            CaseLet(state: /Loadable<T>.failed, then: failedView)
            CaseLet(state: /Loadable<T>.loading, then: loadingView)
            CaseLet(state: /Loadable<T>.idle, then: idleView)
        }
    }
}

extension LoadableStore where Loading == EmptyView, Failed == EmptyView, Idle == EmptyView {
    public init(
        store: Store<Loadable<T>, Action>,
        @ViewBuilder loadedView: @escaping (Store<T, Action>) -> Loaded
    ) {
        self.store = store
        self.loadedView = loadedView
        self.failedView =  { _ in EmptyView() }
        self.loadingView = { _ in EmptyView() }
        self.idleView = { _ in EmptyView() }
    }
}

extension LoadableStore where Loading == Idle {
    public init(
        store: Store<Loadable<T>, Action>,
        @ViewBuilder loadedView: @escaping (Store<T, Action>) -> Loaded,
        @ViewBuilder failedView: @escaping (Store<Error, Action>) -> Failed,
        @ViewBuilder waitingView: @escaping (Store<Void, Action>) -> Idle
    ) {
        self.store = store
        self.loadedView = loadedView
        self.failedView = failedView
        self.loadingView = waitingView
        self.idleView = waitingView
    }
}

public struct LoadableViewStore<T: Equatable, Action, Loaded: View, Failed: View, Loading: View, Idle: View>: View {
    let store: Store<Loadable<T>, Action>
    let loadedView: (ViewStore<T, Action>) -> Loaded
    let failedView: (ViewStore<Void, Action>) -> Failed
    let loadingView: (ViewStore<Void, Action>) -> Loading
    let idleView: (ViewStore<Void, Action>) -> Idle

    public var body: some View {
        LoadableStore(
            store: store
        ) { store in
            WithViewStore(
                store,
                observe: { $0 },
                content: loadedView
            )
        } failedView: { store in
            WithViewStore(
                store.stateless,
                content: failedView
            )
        } loadingView: { store in
            WithViewStore(
                store,
                content: loadingView
            )
        } idleView: { store in
            WithViewStore(
                store,
                content: idleView
            )
        }
    }
}

extension LoadableViewStore where Loading == EmptyView, Failed == EmptyView, Idle == EmptyView {
    public init(
        loadable: Store<Loadable<T>, Action>,
        @ViewBuilder loadedView: @escaping (ViewStore<T, Action>) -> Loaded
    ) {
        self.init(
            store: loadable,
            loadedView: loadedView,
            failedView: { _ in EmptyView() },
            loadingView: { _ in EmptyView() },
            idleView: { _ in EmptyView() }
        )
    }
}

extension LoadableViewStore where Loading == Idle {
    public init(
        loadable: Store<Loadable<T>, Action>,
        @ViewBuilder loadedView: @escaping (ViewStore<T, Action>) -> Loaded,
        @ViewBuilder failedView: @escaping (ViewStore<Void, Action>) -> Failed,
        @ViewBuilder waitingView: @escaping (ViewStore<Void, Action>) -> Idle
    ) {
        self.init(
            store: loadable,
            loadedView: loadedView,
            failedView: failedView,
            loadingView: waitingView,
            idleView: waitingView
        )
    }
}
