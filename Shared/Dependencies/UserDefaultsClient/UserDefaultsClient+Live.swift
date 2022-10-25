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
            dataForKey: userDefaults.data(forKey:),
            boolForKey: userDefaults.bool(forKey:),
            doubleForKey: userDefaults.double(forKey:),
            intForKey: userDefaults.integer(forKey:),
            setBool: { key, value in
                Task(operation: {
                    userDefaults.set(value, forKey: key)
                })
            },
            setInt: { key, value in
                Task(operation: {
                    userDefaults.set(value, forKey: key)
                })
            },
            setDouble: { key, value in
                Task(operation: {
                    userDefaults.set(value, forKey: key)
                })
            },
            setData: { key, value in
                Task(operation: {
                    userDefaults.set(value, forKey: key)
                })
            },
            remove: { key in
                Task(operation: {
                    userDefaults.removeObject(forKey: key)
                })
            })
    }()
}
