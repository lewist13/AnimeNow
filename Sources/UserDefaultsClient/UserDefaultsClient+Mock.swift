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
        false
    } doubleForKey: { _ in
        0
    } intForKey: { _ in
        0
    } setBool: { _, _ in
        ()
    } setInt: { _, _ in
        ()
    } setDouble: { _, _ in
        ()
    } setData: { _, _ in
        ()
    } remove: { _ in
        ()
    }
}
