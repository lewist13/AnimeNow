//
//  NotificationCenter+Async.swift
//  Anime Now!
//
//  Created by ErrorErrorError on 11/1/22.
//  
//

import Foundation

public extension NotificationCenter {
    @discardableResult
    func observeNotifications(
        from notification: Notification.Name
    ) -> AsyncStream<Any?> {
        AsyncStream { continuation in
            let reference = NotificationCenter.default.addObserver(
                forName: notification,
                object: nil,
                queue: nil
            ) { notif in
                continuation.yield(notif.object)
            }

            continuation.onTermination = { @Sendable _ in
                NotificationCenter.default.removeObserver(reference)
            }
        }
    }
}
