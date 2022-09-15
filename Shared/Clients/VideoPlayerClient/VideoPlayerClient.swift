//
//  File.swift
//  Anime Now!
//
//  Created by Erik Bautista on 9/14/22.
//

import Foundation
import ComposableArchitecture

struct VideoPlayerClient {
    let play: (URL) -> Effect<Never, Never>
    let resume: () -> Effect<Never, Never>
    let pause: () -> Effect<Never, Never>
    let stop: () -> Effect<Never, Never>
}

extension VideoPlayerClient {
    enum Action: Equatable {
        
    }
}
