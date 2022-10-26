//
//  UserDefaultsClient.swift
//  Anime Now!
//
//  Created by ErrorErrorError on 9/13/22.
//

import Foundation
import ComposableArchitecture

struct UserDefaultsClient {
    let dataForKey: (Keys) -> Data?
    let boolForKey: (Keys) -> Bool
    let doubleForKey: (Keys) -> Double
    let intForKey: (Keys) -> Int
    let setBool: (Keys, Bool) async -> Void
    let setInt: (Keys, Int) async -> Void
    let setDouble: (Keys, Double) async -> Void
    let setData: (Keys, Data) async -> Void
    let remove: (Keys) async -> Void
}

extension UserDefaultsClient {
    enum Keys: String, CustomStringConvertible {
        case compactEpisodes

        var description: String {
            self.rawValue
        }
    }
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
