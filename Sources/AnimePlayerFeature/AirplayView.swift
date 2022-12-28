//
//  AirplayView.swift
//  Anime Now!
//
//  Created by ErrorErrorError on 9/23/22.
//

import AVKit
import SwiftUI
import Foundation
import ViewComponents

public struct AirplayView: PlatformAgnosticViewRepresentable {
    public init() { }

    public func makeCoordinator() -> Coordinator {
        .init()
    }

    public func makePlatformView(context: Context) -> AVRoutePickerView {
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

    public func updatePlatformView(_ view: AVRoutePickerView, context: Context) {}

    static func dismantlePlatformView(_ platformView: AVRoutePickerView, coordinator: Coordinator) {}

    public class Coordinator: NSObject, AVRoutePickerViewDelegate {
        public func routePickerViewDidEndPresentingRoutes(_ routePickerView: AVRoutePickerView) {}

        public func routePickerViewWillBeginPresentingRoutes(_ routePickerView: AVRoutePickerView) {}
    }
}
