//
//  UserDefaultsClient+Live.swift
//  Anime Now!
//
//  Created by Erik Bautista on 9/14/22.
//

import Foundation


extension UserDefaultsClient {
    static let live: Self = {
        let userDefaults = UserDefaults.standard

        return Self.init(
            dataForKey: userDefaults.data(forKey:),
            boolForKey: userDefaults.bool(forKey:),
            doubleForKey: userDefaults.double(forKey:),
            intForKey: userDefaults.integer(forKey:),
            setBool: { key, value in
                .fireAndForget {
                    userDefaults.set(value, forKey: key)
                }
            },
            setInt: { key, value in
                .fireAndForget {
                    userDefaults.set(value, forKey: key)
                }
            },
            setDouble: { key, value in
                .fireAndForget {
                    userDefaults.set(value, forKey: key)
                }
            },
            setData: { key, value in
                .fireAndForget {
                    userDefaults.set(value, forKey: key)
                }
            },
            remove: { key in
                .fireAndForget {
                    userDefaults.removeObject(forKey: key)
                }
            })
    }()
}
