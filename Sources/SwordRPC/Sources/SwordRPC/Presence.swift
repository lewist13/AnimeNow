//
//  Presence.swift
//  SwordRPC
//
//  Created by Spotlight Deveaux on 3/26/22.
//

import Foundation

extension SwordRPC {
    /// Sets the presence for this RPC connection.
    /// The presence is guaranteed to be set within 15 seconds of call
    /// in accordance with Discord ratelimits.
    ///
    /// If the presence is set before RPC is connected, it is discarded.
    ///
    /// - Parameter presence: The presence to display.
    public func setPresence(_ presence: RichPresence?) {
        Task { [weak self] in
            var args = [String : RequestArg]()
            args["pid"] = .int(.init(pid))
            args["activity"] = presence != nil ? .activity(presence!) : nil

            try? await self?.discordSocket?.write(
                Command(
                    cmd: .setActivity,
                    args: args
                ),
                type: .frame
            )
        }
    }
}
