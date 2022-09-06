//
//  Models.swift
//  Anime Now! (iOS)
//
//  Created by Erik Bautista on 9/6/22.
//

import Foundation
import SociableWeaver

protocol GraphQLResponseResult: Decodable {
    static var query: Weave { get }
}

struct GraphQLResponse<T: GraphQLResponseResult>: Decodable {
    let data: T

    enum CodingKeys: String, CodingKey {
        case data
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        let dictionary = try values.decode([String: T].self, forKey: .data)
        var queryName = String(describing: T.self)
        queryName = queryName.prefix(1).lowercased() + queryName.dropFirst()

        guard let value = dictionary[queryName] else {
            throw DecodingError.valueNotFound(T.self, .init(codingPath: [CodingKeys.data], debugDescription: "Could not parse data"))
        }
        self.data = value
    }
}

struct GraphQLPaylod: Codable, Equatable {
    let query: String
    var operationName: String? = nil
    var variables: [String: String] = [:]
}

extension Weave {
    func encode(removeOperation: Bool = true) -> String {
        if (removeOperation) {
            let output = String("\(self)".split(separator: "{", maxSplits: 1, omittingEmptySubsequences: true).last ?? "")
            return  "{\(output)"
        } else {
            return "{ \(description) }"
        }
    }
}

