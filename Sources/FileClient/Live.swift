//
//  Live.swift
//  
//
//  Created by ErrorErrorError on 1/16/23.
//  
//

import Foundation
import ComposableArchitecture

extension FileClient: DependencyKey {
    public static let liveValue = {
        let mainDirectory = Self.applicationDirectory

        if !FileManager.default.fileExists(atPath: mainDirectory.path) {
            try? FileManager.default.createDirectory(
                at: mainDirectory,
                withIntermediateDirectories: true
            )
        }

        return Self(
            delete: {
                try FileManager.default.removeItem(
                    at: mainDirectory
                        .appendingPathComponent($0)
                        .appendingPathExtension("json")
                )
            },
            load: {
                try Data(
                    contentsOf: mainDirectory
                        .appendingPathComponent($0)
                        .appendingPathExtension("json")
                )
            },
            save: {
                try $1.write(
                    to: mainDirectory
                        .appendingPathComponent($0)
                        .appendingPathExtension("json")
                )
            }
        )
    }()
}

extension FileClient {
    public static let applicationDirectory = FileManager.default
        .urls(for: .applicationSupportDirectory, in: .userDomainMask)
        .first!
        .appendingPathComponent(
            Bundle.main.bundleIdentifier ?? "com.errorerrorerror.animenow",
            isDirectory: true
        )
}
