//
//  Source.swift
//  Anime Now!
//
//  Created by Erik Bautista on 9/12/22.
//

import Foundation

struct Source: Decodable {
    let id: String
    let url: URL
    let provider: String
    let subbed: Bool
}
