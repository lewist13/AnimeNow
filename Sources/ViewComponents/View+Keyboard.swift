//  View+Keyboard.swift
//  Anime Now! (macOS)
//
//  Created by ErrorErrorError on 10/29/22.
//  
//

#if os(macOS)
import SwiftUI
import AppKit

extension View {
    public func onKeyDown(
        _ onKeyDown: @escaping (KeyCommandsHandlerModifier.KeyCommands) -> Void
    ) -> some View {
        self.modifier(KeyCommandsHandlerModifier(onKeyDown: onKeyDown))
    }
}

public struct KeyCommandsHandlerModifier: ViewModifier {
    public enum KeyCommands: UInt16 {
        case spaceBar = 49
        case leftArrow = 123
        case rightArrow = 124
        case downArrow = 125
        case upArrow = 126
    }

    var onKeyDown: (KeyCommands) -> Void

    public func body(content: Content) -> some View {
        content.background(
            Representable(onKeyDown: onKeyDown)
        )
    }
}

extension KeyCommandsHandlerModifier {
    struct Representable: NSViewRepresentable {
        var onKeyDown: (KeyCommands) -> Void

        func makeNSView(context: Context) -> NSView {
            let view = EventView(onKeyDown)
            return view
        }

        func updateNSView(_ nsView: NSView, context: Context) {}
    }

    class EventView: NSView {
        var onKeyDown: (KeyCommands) -> Void

        var observer: Any?

        init(
            _ onKeyDown: @escaping (KeyCommands) -> Void
        ) {
            self.onKeyDown = onKeyDown
            super.init(frame: .zero)

            observer = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] (event) -> NSEvent? in
                guard let keyDown = KeyCommands(rawValue: event.keyCode) else { return event }
                DispatchQueue.main.async { [weak self] in self?.onKeyDown(keyDown) }
                return nil
            }
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        deinit {
            guard let observer = observer else {
                return
            }

            NSEvent.removeMonitor(observer)
        }
    }
}
#endif
