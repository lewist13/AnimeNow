//
//  SceneDelegate.swift
//  Anime Now! (iOS)
//
//  Created by ErrorErrorError on 10/9/22.
//

import UIKit
import ComposableArchitecture

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    let store = Store(
      initialState: AppReducer.State(),
      reducer: AppReducer()
    )

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
        let viewStore = ViewStore(store)
        viewStore.send(.appDelegate(.appDidEnterBackground))
        print("Scene will resign active")
    }

    func sceneDidDisconnect(_ scene: UIScene) {
        let viewStore = ViewStore(store)
        viewStore.send(.appDelegate(.appWillTerminate))
        print("Scene Did Disconnect")
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        let viewStore = ViewStore(store)
        viewStore.send(.appDelegate(.appDidEnterBackground))
        print("Scene did Enter background")
    }
}
