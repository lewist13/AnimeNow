//
//  Models.swift
//  Anime Now! (iOS)
//
//  Created by Erik Bautista on 9/6/22.
//

import Foundation
import SociableWeaver

protocol GraphQLArgument {
    func getValue() -> ArgumentValueRepresentable
    var description: String { get }
}

protocol GraphQLArgumentOptions {
    associatedtype ArgumentOptions
    associatedtype Argument: GraphQLArgument
}

//protocol GraphQLQueryObject {
//    static func createQueryObject(_ name: CodingKey) -> Object
//}

protocol GraphQLQuery: Decodable, GraphQLArgumentOptions {
    static func createQuery(_ arguments: ArgumentOptions) -> Weave
}

enum GraphQL {
    struct Paylod: Codable, Equatable {
        let query: String
        var operationName: String? = nil
        var variables: [String: String] = [:]
    }

    struct Response<T: Decodable>: Decodable {
        let data: T
    }

    struct NodeList<T: Decodable>: Decodable {
        let nodes: [T]
        let pageInfo: PageInfo

        enum CodingKeys: String, CodingKey {
            case nodes
            case pageInfo
        }

        init(from decoder: Decoder) throws {
            let values = try decoder.container(keyedBy: CodingKeys.self)
            let throwables = try values.decode([Throwable<T>].self, forKey: .nodes)
            nodes = throwables.compactMap { try? $0.result.get() }
            pageInfo = try values.decode(PageInfo.self, forKey: .pageInfo)
        }
    }

    struct PageInfo: Decodable {
        let endCursor: String?
        let hasNextPage: Bool
        let hasPreviousPage: Bool
        let startCursor: String?

        static func createQueryObject(
            _ name: CodingKey
        ) -> Object {
            Object(name) {
                Field(PageInfo.CodingKeys.endCursor)
                Field(PageInfo.CodingKeys.hasNextPage)
                Field(PageInfo.CodingKeys.hasPreviousPage)
                Field(PageInfo.CodingKeys.startCursor)
            }
        }
    }
}


extension Weave {
    public func format(removeOperation: Bool = true) -> String {
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
