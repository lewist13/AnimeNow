////  View+Hovered.swift
//  Anime Now! (macOS)
//
//  Created by ErrorErrorError on 10/23/22.
//  
//

import SwiftUI

extension View {
    func mouseEvents(_ mouseActive: @escaping (Bool) -> Void) -> some View {
        modifier(MouseInsideModifier(mouseActive))
    }
}

struct MouseInsideModifier: ViewModifier {
    let mouseActive: (Bool) -> Void

    init(_ mouseActive: @escaping (Bool) -> Void) {
        self.mouseActive = mouseActive
    }

    func body(content: Content) -> some View {
        content.background(
            GeometryReader { proxy in
                Representable(
                    mouseIsInside: mouseActive,
                    frame: proxy.frame(in: .global)
                )
            }
        )
    }

    private struct Representable: NSViewRepresentable {
        let mouseIsInside: (Bool) -> Void
        let frame: NSRect

        func makeCoordinator() -> Coordinator {
            let coordinator = Coordinator()
            coordinator.mouseIsInside = mouseIsInside
            return coordinator
        }

        class Coordinator: NSResponder {
            var mouseIsInside: ((Bool) -> Void)?
            
            override func mouseEntered(with event: NSEvent) {
                mouseIsInside?(true)
            }

            override func mouseExited(with event: NSEvent) {
                mouseIsInside?(false)
            }

            override func mouseMoved(with event: NSEvent) {
                mouseIsInside?(true)
            }
        }

        func makeNSView(context: Context) -> NSView {
            let view = NSView(frame: frame)

            let options: NSTrackingArea.Options = [
                .mouseEnteredAndExited,
//                .inVisibleRect,
                .activeAlways,
                .mouseMoved,
                .enabledDuringMouseDrag
            ]

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
