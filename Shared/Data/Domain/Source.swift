//
//  Source.swift
//  Anime Now!
//
//  Created by Erik Bautista on 9/12/22.
//

import Foundation

struct Source: Equatable, Identifiable {
    let id: String
    let url: URL
    let provider: String
    let subbed: Bool
}

extension Source {
    static let mock = [
        Source(
            id: "",
            url: URL(string: "/")!,
            provider: "",
            subbed: false
        )
    ]
}
