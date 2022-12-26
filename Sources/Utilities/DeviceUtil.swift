//
//  DeviceUtil.swift
//  Anime Now! (iOS)
//
//  Created by ErrorErrorError on 10/15/22.
//

import SwiftUI
import Foundation

public enum DeviceUtil {
    public static var isPad: Bool {
        #if os(iOS)
        UIDevice.current.userInterfaceIdiom == .pad
        #else
        false
        #endif
    }

    public static var isPhone: Bool {
        #if os(iOS)
        UIDevice.current.userInterfaceIdiom == .phone
        #else
        false
        #endif
    }

    public static var isMac: Bool {
        !isPad && !isPhone
    }

    public static var hasBottomIndicator: Bool {
        #if os(iOS)
        if let keyWindow = UIApplication.shared.connectedScenes.compactMap({ $0 as? UIWindowScene }).flatMap({ $0.windows }).first(where: { $0.isKeyWindow }),
            keyWindow.safeAreaInsets.bottom > 0 {
                return true
        }
        #endif
        return false
    }
}
