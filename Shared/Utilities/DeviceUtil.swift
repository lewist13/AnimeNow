//
//  DeviceUtil.swift
//  Anime Now! (iOS)
//
//  Created by Erik Bautista on 10/15/22.
//

import SwiftUI
import Foundation

struct DeviceUtil {
    static var isPad: Bool {
        #if os(iOS)
        UIDevice.current.userInterfaceIdiom == .pad
        #else
        false
        #endif
    }

    static var isPhone: Bool {
        #if os(iOS)
        UIDevice.current.userInterfaceIdiom == .phone
        #else
        false
        #endif
    }

    static var isMac: Bool {
        !isPad && !isPhone
    }
}
