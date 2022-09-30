//
//  HapticEngineClient.swift
//  wLED Hue (iOS)
//
//  Created by Erik Bautista on 7/26/22.
//

import Foundation
import ComposableArchitecture
import CoreHaptics

struct HapticEngineClient {
    let create: (_ id: AnyHashable) -> Effect<Void, HapticEngineClientError>

    let play: (_ id: AnyHashable) -> Effect<Never, Never>

    let destroy: (_ id: AnyHashable) -> Effect<Never, Never>
}

extension HapticEngineClient {
    enum HapticEngineClientError: Error {
        case alreadyCreatedForId
        case failedToCreate
        case failedToDestroy
    }
}
