////  View+Hovered.swift
//  Anime Now! (macOS)
//
//  Created by ErrorErrorError on 10/23/22.
//  
//

import AppKit
import SwiftUI

extension View {
    func mouseEvents(options: NSTrackingArea.Options, _ mouseEvents: @escaping (NSEvent.EventType) -> Void) -> some View {
        modifier(
            MouseEventsModifier(
                options,
                mouseEvents
            )
        )
    }
}

struct MouseEventsModifier: ViewModifier {
    let options: NSTrackingArea.Options
    let mouseEvents: (NSEvent.EventType) -> Void

    init(
        _ options: NSTrackingArea.Options,
        _ mouseEvents: @escaping (NSEvent.EventType) -> Void
    ) {
        self.options = options
        self.mouseEvents = mouseEvents
    }

    func body(content: Content) -> some View {
        content.background(
            GeometryReader { proxy in
                Representable(
                    options: options,
                    onMouseEvent: mouseEvents,
                    frame: proxy.frame(in: .global)
                )
            }
        )
    }

    private struct Representable: NSViewRepresentable {
        let options: NSTrackingArea.Options
        let onMouseEvent: (NSEvent.EventType) -> Void
        let frame: NSRect

        func makeCoordinator() -> Coordinator {
            let coordinator = Coordinator()
            coordinator.onMouseEvent = onMouseEvent
            return coordinator
        }

        func makeNSView(context: Context) -> NSView {
            let view = NSView(frame: frame)
            updateTrackingAreas(view: view, context: context)
            return view
        }

        func updateNSView(_ nsView: NSView, context: Context) {
            updateTrackingAreas(view: nsView, context: context)
        }

        private func updateTrackingAreas(view: NSView, context: Context) {
            Representable.dismantleNSView(view, coordinator: context.coordinator)

            let trackingArea = NSTrackingArea(
                rect: frame,
                options: options,
                owner: context.coordinator,
                userInfo: nil
            )

            view.addTrackingArea(trackingArea)
        }

        static func dismantleNSView(_ nsView: NSView, coordinator: Coordinator) {
            nsView.trackingAreas.forEach { nsView.removeTrackingArea($0) }
        }

        class Coordinator: NSResponder {
            var onMouseEvent: ((NSEvent.EventType) -> Void)?

            override func mouseEntered(with event: NSEvent) {
                onMouseEvent?(.mouseEntered)
            }

            override func mouseExited(with event: NSEvent) {
                onMouseEvent?(.mouseExited)
            }

            override func mouseMoved(with event: NSEvent) {
                onMouseEvent?(.mouseMoved)
            }
        }
    }
}
