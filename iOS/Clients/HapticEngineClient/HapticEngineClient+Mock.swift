//
//  HapticEngineClient+Mock.swift
//  wLED Hue (iOS)
//
//  Created by Erik Bautista on 7/26/22.
//

import Foundation

extension HapticEngineClient {
    static let mock = HapticEngineClient(
        create: { _ in .none },
        play: { _ in .none },
        destroy: { _ in .none }
    )
}
