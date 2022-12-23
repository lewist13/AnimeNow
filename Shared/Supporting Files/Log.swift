//  Log.swift
//  Anime Now! (macOS)
//
//  Created by ErrorErrorError on 12/20/22.
//  
//

import OSLog
import Foundation

public final class Logger {
    static func log<M: CustomStringConvertible>(
        _ level: OSLogType = .debug,
        _ message: M,
        fileName: String = #file,
        functionName: String = #function,
        lineNumber: Int = #line
    ) {
        os_log(
            "%{public}@",
            log: .base,
            type: level,
            "\((fileName as NSString).lastPathComponent) - \(functionName) at line \(lineNumber): \(message)"
        )
    }
}

extension OSLog {
    fileprivate static let base = OSLog(subsystem: Bundle.main.bundleIdentifier ?? "com.errorerrorerror.anime-now", category: "app")
}
