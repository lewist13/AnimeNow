//
//  SkipTime.swift
//  Anime Now!
//
//  Created by Erik Bautista on 10/11/22.
//

import Foundation

struct SkipTime: Equatable {
    let startTime: Double   // 0...1
    let endTime: Double     // 0...1
    let type: Option

    enum Option: Equatable {
        case recap
        case opening
        case ending
        case mixedOpening
        case mixedEnding
    }

    func isInRange(_ progress: Double) -> Bool {
        startTime <= progress && progress <= endTime
    }
}

