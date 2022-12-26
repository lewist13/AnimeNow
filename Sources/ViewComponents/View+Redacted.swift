//
//  View+Redacted.swift
//  Anime Now! (iOS)
//
//  Created by ErrorErrorError on 9/26/22.
//

import Foundation
import SwiftUI

extension View {
    @ViewBuilder
    public func placeholder(active: Bool, duration: Double = 1.5) -> some View {
        Group {
            if active {
                self.redacted(reason: .placeholder)
            } else {
                self.unredacted()
            }
        }
        .shimmering(active: active, duration: duration)
    }
}
