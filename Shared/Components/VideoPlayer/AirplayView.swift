//
//  AirplayView.swift
//  Anime Now! (iOS)
//
//  Created by ErrorErrorError on 9/23/22.
//

import SwiftUI
import Foundation
import AVKit

struct AirplayView: PlatformAgnosticViewRepresentable {
    func makeCoordinator() -> Coordinator {
        .init()
    }

    func makePlatformView(context: Context) -> AVRoutePickerView {
        let view = AVRoutePickerView(frame: .zero)
        view.delegate = context.coordinator

        #if os(iOS)
        view.prioritizesVideoDevices = true
        view.tintColor = .white
        #elseif os(macOS)
        view.isRoutePickerButtonBordered = false
        view.setRoutePickerButtonColor(.white, for: .normal)
        #endif

        return view
    }

    func updatePlatformView(_ view: AVRoutePickerView, context: Context) {}

    static func dismantlePlatformView(_ platformView: AVRoutePickerView, coordinator: Coordinator) {}

    class Coordinator: NSObject, AVRoutePickerViewDelegate {
        func routePickerViewDidEndPresentingRoutes(_ routePickerView: AVRoutePickerView) {}

        func routePickerViewWillBeginPresentingRoutes(_ routePickerView: AVRoutePickerView) {}
    }
}
