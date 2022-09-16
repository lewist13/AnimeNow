//
//  VideoPlayerClient+Mock.swift
//  Anime Now!
//
//  Created by Erik Bautista on 9/14/22.
//

import Foundation

extension VideoPlayerClient {
    static let mock = Self.init(
        play: { _ in
            .none
        },
        resume: { .none },
        pause: { .none },
        stop: { .none },
        seek: { _ in .none }
    )
}
