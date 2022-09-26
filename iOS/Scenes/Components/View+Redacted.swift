//
//  View+Redacted.swift
//  Anime Now! (iOS)
//
//  Created by Erik Bautista on 9/26/22.
//

import Foundation
import SwiftUI

extension View {
    @ViewBuilder
    func placeholder(active: Bool) -> some View {
        Group {
            if active {
                self.redacted(reason: .placeholder)
            } else {
                self.unredacted()
            }
        }
        .shimmering(active: active)
    }
}
