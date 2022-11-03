////  NotificationCenter+Async.swift
//  Anime Now!
//
//  Created by ErrorErrorError on 11/1/22.
//  
//

import Foundation

extension NotificationCenter {
    func observeNotifications(
        from notification: Notification.Name
    ) -> AsyncStream<Void> {
        AsyncStream { continuation in
            let reference = NotificationCenter.default.addObserver(
                forName: notification,
                object: nil,
                queue: nil
            ) { _ in
                continuation.yield(())
            }
            
            continuation.onTermination = { @Sendable _ in
                NotificationCenter.default.removeObserver(reference)
            }
        }
    }
}
