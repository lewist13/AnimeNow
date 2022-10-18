//
//  HapticClient.swift
//  wLED Hue (iOS)
//
//  Created by Erik Bautista on 7/26/22.
//

import Foundation
import ComposableArchitecture
import CoreHaptics

struct HapticClient {
    let play: () -> Effect<Never, Never>
}
