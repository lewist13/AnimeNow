//
//  RPC.swift
//  SwordRPC
//
//  Created by Alejandro Alonso
//  Copyright © 2017 Alejandro Alonso. All rights reserved.
//

import Foundation
import FlyingSocks

extension SwordRPC {
    func connect() async {
        print("[SwordRPC] - Attempting to connect to Discord...")
        let bundleID = Bundle.main.infoDictionary?["CFBundleIdentifier"] as? String ?? ""
        let tempDir = FileManager.default.temporaryDirectory
            .relativePath
            .replacingOccurrences(of: "\(bundleID)/", with: "")

        for port in 0..<10 {
            do {
                let socket = try await AsyncSocket(socket: .init(domain: AF_UNIX), pool: .client)
                try await socket.connect(to: .unix(path: "\(tempDir)/discord-ipc-\(port)"))
                try await handleSocketConnection(socket)
                print("[SwordRPC] - Disconnected from discord.")
            } catch {
                discordSocket = nil
                continue
            }
        }
        print("[SwordRPC] - Failed to connect to discord.")
    }

    private func handleSocketConnection(_ socket: AsyncSocket) async throws {
        try await withThrowingTaskGroup(of: Void.self) { group in
            // Initial Communication
            group.addTask {
                let authRequest = AuthorizationRequest(version: 1, clientId: self.appId)
                try await socket.write(authRequest, type: .handshake)

                for event in EventType.activities {
                    try await socket.write(
                        Command(
                            cmd: .subscribe,
                            evt: event
                        ),
                        type: .frame
                    )
                }
            }

            group.addTask {
                do {
                    for try await response in socket.responses {
                        try await self.handleResponse(response, socket)
                    }
                } catch {
                    print(error)
                }
            }

            try await group.waitForAll()
        }
    }

    private func handleResponse(
        _ response: DiscordResponse,
        _ socket: AsyncSocket
    ) async throws {
        switch response.opCode {
        case .frame:
            if let event: Event = try? response.payload.toObject() {
                try await handleEvent(event, socket)
            } else {
                // Some events don't have evt. Those events are typically considered as event sent to the
                // discord client.
            }

        case .handshake:
            break

        case .close:
            break

        case .ping:
            try await socket.write(response.payload, type: .pong)

        case .pong:
            break
        }
    }

    private func handleEvent(
        _ event: Event,
        _ socket: AsyncSocket
    ) async throws {
        switch event.evt {
        case .error:
            break

        case .join:
            break

        case .joinRequest:
            break

        case .ready:
            print("[SwordRPC] - Connected to discord successfully.")
            discordSocket = socket

        case .spectate:
            break
        }
    }
}

struct DiscordResponse {
    let opCode: OpCode
    let payload: Data
}

struct AsyncDiscordResponses: AsyncSequence, AsyncIteratorProtocol {
    typealias AsyncIterator = Self
    typealias Element = DiscordResponse

    enum Error: Swift.Error {
        case invalidResponse
        case invalidPayloadSize
    }

    let socket: AsyncSocket

    mutating func next() async throws -> DiscordResponse? {
        let opRaw = try await socket.read(bytes: 4)
            .withUnsafeBytes { $0.load(as: UInt32.self) }

        guard let op = OpCode(rawValue: opRaw) else {
            throw Error.invalidResponse
        }

        let payloadLength = try await socket.read(bytes: 4)
            .withUnsafeBytes { $0.load(as: UInt32.self) }

        let payload = try await socket.read(bytes: Int(payloadLength))

        return .init(
            opCode: op,
            payload: .init(payload)
        )
    }

    func makeAsyncIterator() -> Self {
        self
    }
}

extension AsyncSocket {
    var responses: AsyncDiscordResponses {
        .init(socket: self)
    }

    func write<O: Encodable>(_ request: O, type: OpCode) async throws {
        var payload = try request.toData()
        var opRaw = type.rawValue
        var buffer = Data()
        buffer.append(.init(bytes: &opRaw, count: MemoryLayout<OpCode.RawValue>.size))
        buffer.append(.init(bytes: &payload.count, count: MemoryLayout<UInt32>.size))
        buffer.append(payload)

        try await write(buffer)
    }
}
