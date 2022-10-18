//
//  SceneDelegate.swift
//  Anime Now! (iOS)
//
//  Created by ErrorErrorError on 10/9/22.
//

import UIKit
import SwiftUI

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        if let windowScene = scene as? UIWindowScene {
            let window = UIWindow(windowScene: windowScene)
            window.rootViewController = AnimeNowHostingController(
                wrappedView:
                    ContentView(
                        store: .init(
                            initialState: .init(),
                            reducer: ContentCore.reducer,
                            environment: .live
                        )
                    )
            )
            self.window = window
            window.makeKeyAndVisible()
        }
    }
}
