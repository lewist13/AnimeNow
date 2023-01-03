//
//  SwordRPC.swift
//  SwordRPC
//
//  Created by Alejandro Alonso
//  Copyright © 2017 Alejandro Alonso. All rights reserved.
//

import Foundation
import FlyingSocks

public class SwordRPC {

    // MARK: Public

    public var isRunning: Bool { taskRunner != nil }
    public var isConnected: Bool { discordSocket != nil }

    // MARK: Internal

    let appId: String
    var pid: Int32 = { ProcessInfo.processInfo.processIdentifier }()
    var discordSocket: AsyncSocket?

    // MARK: Private

    private let maxRetryCount: Int
    private let retryDuration: Int
    private var retryCount = 0
    private var taskRunner: Task<Void, Error>? = nil

    public init(
        appId: String,
        maxRetryCount: Int = 3,
        retryDuration: Int = 20
    ) {
        self.appId = appId
        self.maxRetryCount = max(maxRetryCount, 0)
        self.retryDuration = max(retryDuration, 5)
    }

    public func start() {
        stop()
        taskRunner = Task {
            await connect()

            while retryCount < maxRetryCount || maxRetryCount == 0 {
                print("[SwordRPC] - Will retry to reconnect to Discord client in \(retryDuration) seconds")
                try await Task.sleep(nanoseconds: .init((retryDuration) * 1_000_000_000))
                await connect()
                retryCount += 1
            }

            if retryCount > 0 {
                print("[SwordRPC] - Max retries reached trying to connect to Discord.")
            }
        }
    }

    public func stop() {
        taskRunner?.cancel()
        taskRunner = nil
        try? discordSocket?.close()
        discordSocket = nil
        retryCount = 0
    }

    public func restart() {
        stop()
        restart()
    }

    deinit {
        stop()
    }
}
