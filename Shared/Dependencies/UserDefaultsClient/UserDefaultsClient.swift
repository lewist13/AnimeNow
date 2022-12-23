//
//  UserDefaultsClient.swift
//  Anime Now!
//
//  Created by ErrorErrorError on 9/13/22.
//

import Foundation
import ComposableArchitecture

struct UserDefaultsClient {
    let dataForKey: @Sendable (String) -> Data?
    let boolForKey: @Sendable (String) -> Bool
    let doubleForKey: @Sendable (String) -> Double
    let intForKey: @Sendable (String) -> Int
    let setBool: @Sendable (String, Bool) async -> Void
    let setInt: @Sendable (String, Int) async -> Void
    let setDouble: @Sendable (String, Double) async -> Void
    let setData: @Sendable (String, Data?) async -> Void
    public let remove: @Sendable (String) async -> Void
}

extension UserDefaultsClient {
    struct Key<T> {
        let key: String
        let defaultValue: T

        init(_ key: String, defaultValue: T) {
            self.key = key
            self.defaultValue = defaultValue
        }
    }
}

// Bool

extension UserDefaultsClient.Key<Bool> {
    init(_ key: String) {
        self.key = key
        self.defaultValue = false
    }
}

// Data

extension UserDefaultsClient.Key<Data?> {
    init(_ key: String) {
        self.key = key
        self.defaultValue = nil
    }
}

// Int

extension UserDefaultsClient.Key<Int> {
    init(_ key: String) {
        self.key = key
        self.defaultValue = 0
    }
}

// Double

extension UserDefaultsClient.Key<Double> {
    init(_ key: String) {
        self.key = key
        self.defaultValue = 0
    }
}

extension UserDefaultsClient {
    func `set`(_ key: Key<Bool>, value: Bool?) async {
        await self.setBool(key.key, value ?? key.defaultValue)
    }

    func `set`(_ key: Key<Data?>, value: Data?) async {
        await self.setData(key.key, value ?? key.defaultValue)
    }

    func `set`(_ key: Key<Int>, value: Int?) async {
        await self.setInt(key.key, value ?? key.defaultValue)
    }

    func `set`(_ key: Key<Double>, value: Double?) async {
        await self.setDouble(key.key, value ?? key.defaultValue)
    }

    func `set`<T: Codable>(_ key: Key<T>, value: T?) async {
        await self.setData(key.key, (try? value?.toData()) ?? (try? key.defaultValue.toData()))
    }
}

extension UserDefaultsClient {
    func `get`(_ key: Key<Bool>) -> Bool {
        self.boolForKey(key.key)
    }

    func `get`(_ key: Key<Data?>) -> Data? {
        self.dataForKey(key.key)
    }

    func `get`(_ key: Key<Int>) -> Int {
        self.intForKey(key.key)
    }

    func `get`(_ key: Key<Double>) -> Double {
        self.doubleForKey(key.key)
    }

    func `get`<T: Codable>(_ key: Key<T>) -> T? {
        try? self.dataForKey(key.key)?.toObject()
    }
}

extension UserDefaultsClient {
    func remove<T>(_ key: Key<T>) async {
        await self.remove(key.key)
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
