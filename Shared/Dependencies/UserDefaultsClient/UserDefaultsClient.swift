//
//  UserDefaultsClient.swift
//  Anime Now!
//
//  Created by ErrorErrorError on 9/13/22.
//

import Foundation
import ComposableArchitecture

struct UserDefaultsClient {
    let dataForKey: (String) -> Data?
    let boolForKey: (String) -> Bool
    let doubleForKey: (String) -> Double
    let intForKey: (String) -> Int
    let setBool: (String, Bool) async -> Void
    let setInt: (String, Int) async -> Void
    let setDouble: (String, Double) async -> Void
    let setData: (String, Data) async -> Void
    let remove: (String) async -> Void
}

private enum UserDefaultsClientKey: DependencyKey {
    static let liveValue = UserDefaultsClient.live
    static var previewValue = UserDefaultsClient.mock
}

extension DependencyValues {
    var userDefaultsClient: UserDefaultsClient {
        get { self[UserDefaultsClientKey.self] }
        set { self[UserDefaultsClientKey.self] = newValue }
    }
}
