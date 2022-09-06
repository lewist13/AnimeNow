//
//  RepositoryClient+Mock.swift
//  Anime Now! (iOS)
//
//  Created by Erik Bautista on 9/3/22.
//

import Foundation


extension RepositoryClient {
    static var mock: RepositoryClient {
        return RepositoryClient { _ in
            .none
        } update: { _ in
            .none
        } delete: { _ in
            .none
        } fetch: { _, _ in
            .none
        } count: { _ in
            .none
        } observe: { _ in
            .none
        }
    }
}
