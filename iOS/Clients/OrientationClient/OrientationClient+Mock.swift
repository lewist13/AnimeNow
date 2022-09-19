//
//  OrientationClient+Mock.swift
//  Anime Now!
//
//  Created by Erik Bautista on 9/18/22.
//

import Foundation

extension OrientationClient {
    static let mock = Self { _ in .none }
}
