//
//  HapticClient+Live.swift
//  wLED Hue (iOS)
//
//  Created by ErrorErrorError on 7/26/22.
//

import Foundation
import CoreHaptics
import ComposableArchitecture
import UIKit

extension HapticClient {
    static let live = HapticClient(
        play: {
            .fireAndForget {
                let generator = UISelectionFeedbackGenerator()
                generator.prepare()
                generator.selectionChanged()
            }
        }
    )
}
