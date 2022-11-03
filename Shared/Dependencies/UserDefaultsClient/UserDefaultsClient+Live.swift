//
//  UserDefaultsClient+Live.swift
//  Anime Now!
//
//  Created by ErrorErrorError on 9/14/22.
//

import Foundation
import ComposableArchitecture

extension UserDefaultsClient {
    static let live: Self = {
        let userDefaults = UserDefaults.standard

        return Self.init(
            dataForKey: { userDefaults.data(forKey: $0.rawValue) } ,
            boolForKey: { userDefaults.bool(forKey: $0.rawValue) },
            doubleForKey: { userDefaults.double(forKey: $0.rawValue) },
            intForKey: { userDefaults.integer(forKey: $0.rawValue) },
            setBool: { key, value in
                Task(operation: {
                    userDefaults.set(value, forKey: key.rawValue)
                })
            },
            setInt: { key, value in
                Task(operation: {
                    userDefaults.set(value, forKey: key.rawValue)
                })
            },
            setDouble: { key, value in
                Task(operation: {
                    userDefaults.set(value, forKey: key.rawValue)
                })
            },
            setData: { key, value in
                Task(operation: {
                    userDefaults.set(value, forKey: key.rawValue)
                })
            },
            remove: { key in
                Task(operation: {
                    userDefaults.removeObject(forKey: key.rawValue)
                })
            })
    }()
}

extension UserDefaults: @unchecked Sendable { }
