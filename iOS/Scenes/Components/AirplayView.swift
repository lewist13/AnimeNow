//
//  AirplayView.swift
//  Anime Now! (iOS)
//
//  Created by Erik Bautista on 9/23/22.
//

import SwiftUI
import Foundation
import AVKit

struct AirplayView: UIViewRepresentable {
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIView(context: Context) -> AVRoutePickerView {
        let view = AVRoutePickerView(frame: .zero)
        view.delegate = context.coordinator
        view.prioritizesVideoDevices = true
        view.tintColor = .white
        return view
    }

    func updateUIView(_ uiView: AVRoutePickerView, context: Context) {}

    class Coordinator: NSObject, AVRoutePickerViewDelegate {
        func routePickerViewDidEndPresentingRoutes(_ routePickerView: AVRoutePickerView) {
            
        }

        func routePickerViewWillBeginPresentingRoutes(_ routePickerView: AVRoutePickerView) {
            
        }
    }
}
