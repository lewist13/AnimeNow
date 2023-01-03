//
//  AnimeNowAPI.swift
//  
//
//  Created by ErrorErrorError on 12/26/22.
//  
//

import Foundation

public final class AnimeNowAPI: APIBase {
    public static var shared: AnimeNowAPI = .init()

    public var discordClientKey: String {
        ""
    }

    private init() { }

    public let base = URL(string: "https://api.animenow.app")!
}

// Endpoint

public extension Request where Route == AnimeNowAPI {
}
