//
//  HapticClient+Live.swift
//
//
//  Created by ErrorErrorError on 7/26/22.
//

import Foundation

#if os(iOS)
import CoreHaptics
import UIKit
#endif

extension HapticClient {
    static let live = HapticClient(
        play: {
            #if os(iOS)
            let generator = UISelectionFeedbackGenerator()
            generator.prepare()
            generator.selectionChanged()
            #endif
        }
    )
}
