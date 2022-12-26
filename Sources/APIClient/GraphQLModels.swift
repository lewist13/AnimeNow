//
//  Models.swift
//  Anime Now! (iOS)
//
//  Created by ErrorErrorError on 9/6/22.
//

import Foundation
import SociableWeaver

public protocol GraphQLArgument {
    func getValue() -> ArgumentValueRepresentable
    var description: String { get }
}

public protocol GraphQLQueryObject: Decodable {
    associatedtype Argument
    static func createQueryObject(_ name: String, _ arguments: [Argument]) -> Object
}

extension GraphQLQueryObject {
    public static func createQueryObject(_ name: CodingKey, _ arguments: [Argument] = []) -> Object {
        self.createQueryObject(name.stringValue, arguments)
    }
}

extension GraphQLQueryObject where Argument == Void {
    public static func createQueryObject(_ name: String, _ arguments: [Void] = []) -> Object {
        self.createQueryObject(name, arguments)
    }
}

public protocol GraphQLQuery: Decodable {
    associatedtype QueryOptions
    associatedtype Response
    static func createQuery(_ options: QueryOptions) -> Weave
}

public enum GraphQL {
    public struct Paylod: Codable, Equatable {
        let query: String
        var operationName: String? = nil
        var variables: [String: String] = [:]

        public init(
            query: String,
            operationName: String? = nil,
            variables: [String : String] = [:]
        ) {
            self.query = query
            self.operationName = operationName
            self.variables = variables
        }
    }

    public struct Response<T: Decodable>: Decodable {
        public let data: T
    }

    public struct NodeList<T: Decodable, P: Decodable>: Decodable {
        public let nodes: [T]
        public let pageInfo: P
    }
}

extension Weave {
    public func format(removeOperation: Bool = true) -> String {
        let weave = String("\(self.description)")

        if (removeOperation) {
            let output = String(weave.split(separator: "{", maxSplits: 1, omittingEmptySubsequences: true).last ?? "")
            return  "{\(output)"
        } else {
            return "{ \(weave) }"
        }
    }
}

extension Object {
    public func argument<V: GraphQLArgument>(_ argument: V) -> Self {
        let argumentKey = argument.description
        let value = argument.getValue()
        return self.argument(key: argumentKey, value: value)
    }
}

extension Field {
    public func argument<V: GraphQLArgument>(_ argument: V) -> Self {
        let argumentKey = argument.description
        let value = argument.getValue()
        return self.argument(key: argumentKey, value: value)
    }
}
