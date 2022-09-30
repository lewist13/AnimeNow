//
//  HapticEngineClient+Live.swift
//  wLED Hue (iOS)
//
//  Created by Erik Bautista on 7/26/22.
//

import Foundation
import CoreHaptics
import ComposableArchitecture
import UIKit

extension HapticEngineClient {
    static let live = HapticEngineClient(
        create: { id in
                .result {
//                    guard dependencies[id] == nil else {
//                        return .failure(.alreadyCreatedForId)
//                    }
//
//                    if let engine = try? CHHapticEngine() {
//                        engine.playsHapticsOnly = true
//                        engine.isAutoShutdownEnabled = true
//                        dependencies[id] = engine
//                    } else {
//                        return .failure(.failedToCreate)
//                    }
                    return .success(())
                }
        },
        play: { id in
            .fireAndForget {
                let generator = UISelectionFeedbackGenerator()
                generator.prepare()
                generator.selectionChanged()
//                if let engine = dependencies[id] {
//
//                }
            }
        },
        destroy: { id in
            .fireAndForget {
                dependencies[id] = nil
            }
        }
    )

    private static var dependencies: [AnyHashable : CHHapticEngine] = [:]
}
