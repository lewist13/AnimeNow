//
//  AnimeNowAPI.swift
//  
//
//  Created by ErrorErrorError on 12/26/22.
//  
//

import Foundation

final class AnimeNowAPI: APIBase {
    static var shared: AnimeNowAPI = .init()

    var base = URL(string: "https://api.animenow.app")!
}

// Endpoint

extension Request where Route == AnimeNowAPI {
}
