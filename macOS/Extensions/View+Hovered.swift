////  View+Hovered.swift
//  Anime Now! (macOS)
//
//  Created by ErrorErrorError on 10/23/22.
//  
//

import SwiftUI

extension View {
    func mouseEvents(options: NSTrackingArea.Options, _ mouseActive: @escaping (Bool) -> Void) -> some View {
        modifier(
            MouseInsideModifier(
                options,
                mouseActive
            )
        )
    }
}

struct MouseInsideModifier: ViewModifier {
    let options: NSTrackingArea.Options
    let mouseActive: (Bool) -> Void

    init(
        _ options: NSTrackingArea.Options,
        _ mouseActive: @escaping (Bool) -> Void
    ) {
        self.options = options
        self.mouseActive = mouseActive
    }

    func body(content: Content) -> some View {
        content.background(
            GeometryReader { proxy in
                Representable(
                    options: options,
                    onMouseEvent: mouseActive,
                    frame: proxy.frame(in: .global)
                )
            }
        )
    }

    private struct Representable: NSViewRepresentable {
        let options: NSTrackingArea.Options
        let onMouseEvent: (Bool) -> Void
        let frame: NSRect

        func makeCoordinator() -> Coordinator {
            let coordinator = Coordinator()
            coordinator.onMouseEvent = onMouseEvent
            return coordinator
        }

        class Coordinator: NSResponder {
            var onMouseEvent: ((Bool) -> Void)?

            override func mouseEntered(with event: NSEvent) {
                onMouseEvent?(true)
            }

            override func mouseExited(with event: NSEvent) {
                onMouseEvent?(false)
            }

            override func mouseMoved(with event: NSEvent) {
                onMouseEvent?(true)
            }
        }

        func makeNSView(context: Context) -> NSView {
            let view = NSView(frame: frame)

            let trackingArea = NSTrackingArea(
                rect: frame,
                options: options,
                owner: context.coordinator,
                userInfo: nil
            )

            view.addTrackingArea(trackingArea)

            return view
        }

        func updateNSView(_ nsView: NSView, context: Context) {}

        static func dismantleNSView(_ nsView: NSView, coordinator: Coordinator) {
            nsView.trackingAreas.forEach { nsView.removeTrackingArea($0) }
        }
    }
}
