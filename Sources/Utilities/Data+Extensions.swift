//
//  Data+Extensions.swift
//  Anime Now!
//
//  Created by ErrorErrorError on 10/1/22.
//

import Foundation

extension Encodable {
    public func toData() throws -> Data {
        try JSONEncoder().encode(self)
    }
}

extension Data {
    public func toObject<D: Decodable>() throws -> D {
        try JSONDecoder().decode(D.self, from: self)
    }
}
