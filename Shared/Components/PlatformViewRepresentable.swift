//
//  PlatformViewRepresentable.swift
//  Anime Now!
//
//  Created by ErrorErrorError on 10/12/22.
//

import SwiftUI

#if os(iOS) || os(tvOS)
public typealias PlatformView = UIView
public typealias PlatformViewRepresentable = UIViewRepresentable
#elseif os(macOS)
public typealias PlatformView = NSView
public typealias PlatformViewRepresentable = NSViewRepresentable
#endif

/// Implementers get automatic `UIViewRepresentable` conformance on iOS
/// and `NSViewRepresentable` conformance on macOS.
public protocol PlatformAgnosticViewRepresentable: PlatformViewRepresentable {
    associatedtype PlatformViewType

    func makePlatformView(context: Context) -> PlatformViewType
    func updatePlatformView(_ platformView: PlatformViewType, context: Context)
}

extension PlatformAgnosticViewRepresentable {
    static func dismantlePlatformView(_ platformView: PlatformViewType, coordinator: Coordinator) { }
}

#if os(iOS) || os(tvOS)
public extension PlatformAgnosticViewRepresentable where UIViewType == PlatformViewType {
    func makeUIView(context: Context) -> UIViewType {
        makePlatformView(context: context)
    }

    func updateUIView(_ uiView: UIViewType, context: Context) {
        updatePlatformView(uiView, context: context)
    }

    static func dismantleUIView(_ uiView: UIViewType, coordinator: Coordinator) {
        dismantlePlatformView(uiView, coordinator: coordinator)
    }
}

#elseif os(macOS)
public extension PlatformAgnosticViewRepresentable where NSViewType == PlatformViewType {
    func makeNSView(context: Context) -> NSViewType {
        makePlatformView(context: context)
    }

    func updateNSView(_ nsView: NSViewType, context: Context) {
        updatePlatformView(nsView, context: context)
    }

    static func dismantleNSView(_ nsView: NSViewType, coordinator: Coordinator) {
        dismantlePlatformView(nsView, coordinator: coordinator)
    }
}
#endif
