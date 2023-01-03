//
//  ChromeCastClient+Live.swift
//  
//
//  Created by ErrorErrorError on 1/2/23.
//  
//

import Foundation
import OpenCastSwift

extension ChromeCastClient {
    public static let liveValue: Self = {
        var scanner = CastDeviceScanner()

        return .init(
            scan: { $0 ? scanner.startScanning() : scanner.stopScanning() },
            scannedDevices: {
                if !scanner.isScanning {
                    scanner.startScanning()
                }
                return .init { continuation in
                    continuation.yield(scanner.devices.map(\.device))

                    let retval = NotificationCenter.default.addObserver(
                        forName: CastDeviceScanner.deviceListDidChange,
                        object: scanner,
                        queue: nil
                    ) { _ in
                        continuation.yield(
                            scanner.devices.map(\.device)
                        )
                    }

                    continuation.onTermination = { _ in
                        NotificationCenter.default.removeObserver(retval)
                    }
                }
            }
        )
    }()
}

private extension CastDevice {
    var device: ChromeCastClient.Device {
        .init(
            id: id,
            name: name
        )
    }
}

private class Delegate: CastClientDelegate {
    
}
