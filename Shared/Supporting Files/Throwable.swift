//
//  Throwable.swift
//  Anime Now!
//
//  Created by Erik Bautista on 9/8/22.
//

import Foundation

struct Throwable<T: Decodable>: Decodable {
    let result: Result<T, Error>

    init(from decoder: Decoder) throws {
        let catching = { try T(from: decoder) }
        result = Result(catching: catching)
    }
}
