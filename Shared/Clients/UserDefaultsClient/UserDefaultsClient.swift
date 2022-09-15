//
//  UserDefaultsClient.swift
//  Anime Now!
//
//  Created by Erik Bautista on 9/13/22.
//

import Foundation
import ComposableArchitecture

struct UserDefaultsClient {
    let dataForKey: (String) -> Data?
    let boolForKey: (String) -> Bool
    let doubleForKey: (String) -> Double
    let intForKey: (String) -> Int
    let setBool: (String, Bool) -> Effect<Never, Never>
    let setInt: (String, Int) -> Effect<Never, Never>
    let setDouble: (String, Double) -> Effect<Never, Never>
    let setData: (String, Data) -> Effect<Never, Never>
    let remove: (String) -> Effect<Never, Never>
}
