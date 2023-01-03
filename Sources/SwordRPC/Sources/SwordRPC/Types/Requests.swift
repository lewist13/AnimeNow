//
//  Requests.swift
//
//
//  Created by Spotlight Deveaux on 2022-01-17.
//

import Foundation

/// Describes the format needed for an authorization request.
/// https://discord.com/developers/docs/topics/rpc#authenticating-rpc-authorize-example
struct AuthorizationRequest: Encodable {
    let version: Int
    let clientId: String

    enum CodingKeys: String, CodingKey {
        case version = "v"
        case clientId = "client_id"
    }
}

/// RequestArg permits a union-like type for arguments to encode.
enum RequestArg: Encodable {
    /// An integer value.
    case int(Int)
    /// A string value.
    case string(String)
    /// An activity value.
    case activity(RichPresence)

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case let .int(int):
            try container.encode(int)
        case let .string(string):
            try container.encode(string)
        case let .activity(presence):
            try container.encode(presence)
        }
    }
}


/// A generic format for a payload with a command, possibly used for an event.
struct Command: Encodable {
    /// The type of command to issue to Discord. For normal events, this should be .dispatch.
    let cmd: CommandType
    /// The nonce for this command. It should typically be an automatically generated UUID.
    var nonce: String? = UUID().uuidString
    /// Arguments sent alongside the command.
    var args: [String: RequestArg]?
    /// The event type this command pertains to, if needed.
    var evt: EventType?
}

struct Event: Decodable {
    /// The type of command issue by Discord.
    let cmd: CommandType
    let evt: EventType
}
