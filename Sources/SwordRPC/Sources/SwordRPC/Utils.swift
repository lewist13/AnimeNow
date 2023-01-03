//
//  Utils.swift
//  SwordRPC
//
//  Created by Alejandro Alonso
//  Copyright © 2017 Alejandro Alonso. All rights reserved.
//

import Foundation


extension Encodable {
    func toData() throws -> Data {
        if let `self` = self as? Data {
            return self
        }
        return try JSONEncoder().encode(self)
    }

    func toJSON() throws -> String {
        let result = try toData()
        return String(bytes: result, encoding: .utf8) ?? ""
    }
}

extension Data {
    func toObject<O: Decodable>() throws -> O {
        try JSONDecoder().decode(O.self, from: self)
    }
}
