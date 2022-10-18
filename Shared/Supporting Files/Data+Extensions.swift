//
//  Data+Extensions.swift
//  Anime Now!
//
//  Created by ErrorErrorError on 10/1/22.
//

import Foundation

extension Encodable {
    func toData() -> Data? {
        try? JSONEncoder().encode(self)
    }
}

extension Data {
    func toObject<D: Decodable>() -> D? {
        try? JSONDecoder().decode(D.self, from: self)
    }
}
