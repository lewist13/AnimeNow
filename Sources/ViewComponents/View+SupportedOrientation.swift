//  View+SupportedOrientation.swift
//  
//
//  Created by ErrorErrorError on 12/26/22.
//  
//

#if os(iOS)
import UIKit
import SwiftUI

public struct SupportedOrientationPreferenceKey: PreferenceKey {
    public static var defaultValue: UIInterfaceOrientationMask = .portrait

    public static func reduce(
        value: inout UIInterfaceOrientationMask,
        nextValue: () -> UIInterfaceOrientationMask
    ) {
        value = nextValue()
    }
}

public extension View {
    func supportedOrientation(_ orientation: UIInterfaceOrientationMask) -> some View {
        preference(key: SupportedOrientationPreferenceKey.self, value: orientation)
    }
}
#endif
