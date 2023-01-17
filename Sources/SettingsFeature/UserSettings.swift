//
//  File.swift
//  
//
//  Created by ErrorErrorError on 1/16/23.
//  
//

import Foundation

public struct UserSettings: Codable, Equatable {
    public var preferredProvider: String
    public var discordEnabled: Bool

    public init(
        preferredProvider: String? = nil,
        discordEnabled: Bool = false
    ) {
        self.preferredProvider = preferredProvider ?? "Gogoanime"
        self.discordEnabled = discordEnabled
    }
}
