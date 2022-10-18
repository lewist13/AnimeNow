//
//  HapticClient+Mock.swift
//  wLED Hue (iOS)
//
//  Created by ErrorErrorError on 7/26/22.
//

import Foundation

extension HapticClient {
    static let mock = HapticClient(
        play: { .none }
    )
}
