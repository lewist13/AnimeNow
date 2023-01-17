//
//  File.swift
//  
//
//  Created by ErrorErrorError on 12/30/22.
//  
//

import Foundation

extension DiscordClient {
    public static let noop: Self = .init(
        status: { .never },
        isActive: false,
        isConnected: false,
        setActive: { _ in },
        setActivity: { _ in }
    )
}
