//
//  SceneDelegate.swift
//  Anime Now! (iOS)
//
//  Created by ErrorErrorError on 10/9/22.
//

import UIKit
import AppFeature
import ComposableArchitecture

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    lazy var viewStore = ViewStore(store.stateless)

    var window: UIWindow?

    func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        self.window = (scene as? UIWindowScene).map { UIWindow(windowScene: $0) }
        self.window?.rootViewController = AnimeNowHostingController(
            wrappedView:
                AppView(
                    store: store
                )
        )
        self.window?.makeKeyAndVisible()
    }

    func sceneWillResignActive(_ scene: UIScene) {
        viewStore.send(.appDelegate(.appDidEnterBackground))
    }

    func sceneDidDisconnect(_ scene: UIScene) {
        viewStore.send(.appDelegate(.appWillTerminate))
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        viewStore.send(.appDelegate(.appDidEnterBackground))
    }
}
