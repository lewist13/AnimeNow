//
//  SceneDelegate.swift
//  Anime Now! (iOS)
//
//  Created by ErrorErrorError on 10/9/22.
//

import UIKit
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
        Logger.log(.info, "Scene will resign active")
    }

    func sceneDidDisconnect(_ scene: UIScene) {
        viewStore.send(.appDelegate(.appWillTerminate))
        Logger.log(.info, "Scene Did Disconnect")
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        viewStore.send(.appDelegate(.appDidEnterBackground))
        Logger.log(.info, "Scene did Enter background")
    }
}
