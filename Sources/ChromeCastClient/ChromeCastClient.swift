//
//  ChromeCastClient.swift
//  
//
//  Created by ErrorErrorError on 12/29/22.
//  
//

import Foundation
import ComposableArchitecture

public struct ChromeCastClient {
    public let scan: (Bool) -> Void
    public let scannedDevices: () -> AsyncStream<[Device]>
}

extension ChromeCastClient {
    public struct Device {
        let id: String
        let name: String
    }
}

extension ChromeCastClient: DependencyKey {}

extension DependencyValues {
    public var chromeCastClient: ChromeCastClient {
        get { self[ChromeCastClient.self] }
        set { self[ChromeCastClient.self] = newValue }
    }
}
