//
//  Models.swift
//  Anime Now! (iOS)
//
//  Created by Erik Bautista on 9/6/22.
//

import Foundation
import SociableWeaver


//protocol GraphQLCreateQueryObject: Decodable {
//    associatedtype Output: Weavable
//    static func createQuery(_ name: String, _ arguments: ArgumentOptions) -> Output
//}
//
//protocol GraphQLArgumentOptions {}

// Used in argument enums

protocol GraphQLArgument {
    func getValue() -> ArgumentValueRepresentable
    var description: String { get }
}

protocol GraphQLArgumentOptions {
    associatedtype ArgumentOptions
    associatedtype Argument: GraphQLArgument
}

protocol GraphQLQueryObject {
    static func createQueryObject(_ name: CodingKey) -> Object
}

//protocol GraphQLQueryObject: GraphQLArgumentOptions {
//    static func createQueryObject(_ name: CodingKey, _ arguments: ArgumentOptions) -> Object
//}

protocol GraphQLQuery: Decodable, GraphQLArgumentOptions {
    static func createQuery(_ arguments: ArgumentOptions) -> Weave
}

struct GraphQLResponse<T: GraphQLQuery>: Decodable {
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
            throw DecodingError.valueNotFound(
                T.self,
                .init(
                    codingPath: [CodingKeys.data],
                    debugDescription: "Could not parse data"
                )
            )
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

extension Object {
    func argument<V: GraphQLArgument>(_ argument: V) -> Self {
        let argumentKey = argument.description
        let value = argument.getValue()
        return self.argument(key: argumentKey, value: value)
    }
}

extension Field {
    func argument<V: GraphQLArgument>(_ argument: V) -> Self {
        let argumentKey = argument.description
        let value = argument.getValue()
        return self.argument(key: argumentKey, value: value)
    }
}
