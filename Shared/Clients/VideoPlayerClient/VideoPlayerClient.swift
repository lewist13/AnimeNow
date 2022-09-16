//
//  File.swift
//  Anime Now!
//
//  Created by Erik Bautista on 9/14/22.
//

import Foundation
import ComposableArchitecture
import CoreMedia

struct VideoPlayerClient {
    let play: (URL) -> Effect<Action, Never>
    let resume: () -> Effect<Never, Never>
    let pause: () -> Effect<Never, Never>
    let stop: () -> Effect<Never, Never>
    let seek: (CMTime) -> Effect<Never, Never>
}

extension VideoPlayerClient {
    enum Action: Equatable {
        case updatedPeriodicTime(CMTime)
    }
}
