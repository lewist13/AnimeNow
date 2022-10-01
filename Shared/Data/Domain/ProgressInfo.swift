//
//  Progress.swift
//  Anime Now! (iOS)
//
//  Created by Erik Bautista on 9/29/22.
//

import Foundation
import CoreData

// MARK: ProgressInfo Model

struct ProgressInfo: Hashable, Codable, Identifiable {
    var id: Int16 { number }
    var number: Int16
    var progress: Double
    var lastUpdated: Date
}

extension ProgressInfo {
    var isFinished: Bool {
        return progress >= 0.9
    }
}
