//
//  DeviceInfoClient.swift
//  
//
//  Created by ErrorErrorError on 1/26/23.
//  
//

import Foundation
import ComposableArchitecture

public struct Build {
    public var version: () -> String
    public var gitSha: () -> String
}

extension DependencyValues {
    public var build: Build {
        get { self[Build.self] }
        set { self[Build.self] = newValue }
    }
}

extension Build: DependencyKey {
    public static let liveValue: Build = Self(
        version: { Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown" },
        gitSha: { Bundle.main.infoDictionary?["Commit Version"] as? String ?? "Unknown" }
    )

    public static let previewValue = noop
}

extension Build {
  public static let noop = Self(
    version: { "test" },
    gitSha: { "0000000" }
  )
}
