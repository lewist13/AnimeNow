//
//  BlurView.swift
//  Anime Now! (iOS)
//
//  Created by Erik Bautista on 9/9/22.
//

import SwiftUI

#if os(iOS)
import UIKit

typealias BlurEffectView = UIVisualEffectView
typealias BlurStyle = UIBlurEffect.Style
#else
import AppKit

typealias BlurEffectView = NSVisualEffectView
typealias BlurStyle = NSVisualEffectView.Material
#endif


struct BlurView: PlatformAgnosticViewRepresentable {
    var style: BlurStyle

    func makePlatformView(context: Context) -> BlurEffectView {
        BlurEffectView()
    }

    func updatePlatformView(_ view: BlurEffectView, context: Context) {
        #if os(iOS)
        view.effect = UIBlurEffect(style: style)
        #else
        view.material = style
        #endif
    }

    static func dismantlePlatformView(_ view: BlurEffectView, coordinator: ()) {}
}


struct BlurredButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(.white)
            .aspectRatio(1, contentMode: .fill)
            .padding(12)
    }
}
