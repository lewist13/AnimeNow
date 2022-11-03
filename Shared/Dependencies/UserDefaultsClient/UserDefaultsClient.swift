//
//  UserDefaultsClient.swift
//  Anime Now!
//
//  Created by ErrorErrorError on 9/13/22.
//

import Foundation
import ComposableArchitecture

struct UserDefaultsClient {
    let dataForKey: @Sendable (Keys) -> Data?
    let boolForKey: @Sendable (Keys) -> Bool
    let doubleForKey: @Sendable (Keys) -> Double
    let intForKey: @Sendable (Keys) -> Int
    let setBool: @Sendable (Keys, Bool) async -> Void
    let setInt: @Sendable (Keys, Int) async -> Void
    let setDouble: @Sendable (Keys, Double) async -> Void
    let setData: @Sendable (Keys, Data) async -> Void
    let remove: @Sendable (Keys) async -> Void
}

extension UserDefaultsClient {
    enum Keys: String, CustomStringConvertible {
        case compactEpisodes
        case videoPlayerProvider
        case videoPlayerAudioIsDub
        case videoPlayerSubtitle
        case videoPlayerQuality

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
