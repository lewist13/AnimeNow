//
//  File.swift
//  Anime Now!
//
//  Created by ErrorErrorError on 9/14/22.
//

import Foundation

extension UserDefaultsClient {
    static let mock = Self.init { _ in
        .none
    } boolForKey: { _ in
        return false
    } doubleForKey: { _ in
        return 0
    } intForKey: { _ in
        return 0
    } setBool: { _, _ in
        .none
    } setInt: { _, _ in
        .none
    } setDouble: { _, _ in
        .none
    } setData: { _, _ in
        .none
    } remove: { _ in
        .none
    }
}
