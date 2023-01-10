//
//  Provider.swift
//  
//
//  Created by ErrorErrorError on 1/3/23.
//  
//

import Utilities
import Foundation

public struct ProviderInfo: Hashable, Identifiable, Decodable {
    public var id: String { name }
    public let name: String
    public let logo: String?
    public let isNSFW: Bool
    public let isWorking: Bool

    public init(
        name: String = "",
        logo: String? = nil,
        isNSFW: Bool = false,
        isWorking: Bool = true
    ) {
        self.name = name
        self.logo = logo
        self.isNSFW = isNSFW
        self.isWorking = isWorking
    }
}

extension ProviderInfo: CustomStringConvertible {
    public var description: String { name }
}

public protocol ProviderRepresentable {
    var name: String { get }
    var logo: String? { get }
}

public struct AnimeStreamingProvider: Equatable, Identifiable {
    public var id: String { name }
    public let name: String
    public let logo: String?
    public let episodes: [Episode]

    public init(
        name: String,
        logo: String? = nil,
        episodes: [Episode] = []
    ) {
        self.name = name
        self.logo = logo
        self.episodes = episodes
    }
}
