//
//  BottomSafeAreaInset+View.swift
//  Anime Now!
//
//  Created by ErrorErrorError on 10/19/22.
//  From https://github.com/FiveStarsBlog/CodeSamples/blob/main/SafeAreaInset/content.swift

import SwiftUI

extension View {
    @ViewBuilder
    func bottomSafeAreaInset<OverlayContent: View>(
        _ overlayContent: OverlayContent
    ) -> some View {
        if #available(iOS 15.0, macOS 12.0, *) {
            self.safeAreaInset(edge: .bottom, spacing: 0, content: { overlayContent })
        } else {
            self.modifier(BottomInsetViewModifier(overlayContent: overlayContent))
        }
    }

    @ViewBuilder
    func topSafeAreaInset<OverlayContent: View>(
        _ overlayContent: OverlayContent
    ) -> some View {
        if #available(iOS 15.0, macOS 12.0, *) {
            self.safeAreaInset(edge: .top, spacing: 0, content: { overlayContent })
        } else {
            self.modifier(TopInsetViewModifier(overlayContent: overlayContent))
        }
    }
}

extension View {
    func readSize(onChange: @escaping (CGSize) -> Void) -> some View {
        background(
            GeometryReader { geometryProxy in
                Spacer()
                    .preference(
                        key: FramePreferenceKey.self,
                        value: geometryProxy.size
                    )
            }
        )
        .onPreferenceChange(FramePreferenceKey.self, perform: onChange)
    }
}

private struct FramePreferenceKey: PreferenceKey {
    static var defaultValue: CGSize = .zero
    static func reduce(value: inout CGSize, nextValue: () -> CGSize) {}
}

struct BottomInsetViewModifier<OverlayContent: View>: ViewModifier {
    @Environment(\.bottomSafeAreaInset) var ancestorBottomSafeAreaInset: CGFloat
    var overlayContent: OverlayContent
    @State var overlayContentHeight: CGFloat = 0

    func body(content: Self.Content) -> some View {
        content
            .environment(\.bottomSafeAreaInset, overlayContentHeight + ancestorBottomSafeAreaInset)
            .overlay(
                overlayContent
                    .readSize {
                        overlayContentHeight = $0.height
                    }
                    .padding(.bottom, ancestorBottomSafeAreaInset)
                ,
                alignment: .bottom
            )
    }
}

struct TopInsetViewModifier<OverlayContent: View>: ViewModifier {
    @Environment(\.topSafeAreaInset) var ancestorTopSafeAreaInset: CGFloat
    var overlayContent: OverlayContent
    @State var overlayContentHeight: CGFloat = 0

    func body(content: Self.Content) -> some View {
        content
            .environment(\.topSafeAreaInset, overlayContentHeight + ancestorTopSafeAreaInset)
            .overlay(
                overlayContent
                    .readSize {
                        overlayContentHeight = $0.height
                    }
                    .padding(.bottom, ancestorTopSafeAreaInset)
                ,
                alignment: .bottom
            )
    }
}

struct TopSafeAreaInsetKey: EnvironmentKey {
    static var defaultValue: CGFloat = .zero
}

struct BottomSafeAreaInsetKey: EnvironmentKey {
    static var defaultValue: CGFloat = .zero
}

extension EnvironmentValues {
    var bottomSafeAreaInset: CGFloat {
        get { self[BottomSafeAreaInsetKey.self] }
        set { self[BottomSafeAreaInsetKey.self] = newValue }
    }

    var topSafeAreaInset: CGFloat {
        get { self[TopSafeAreaInsetKey.self] }
        set { self[TopSafeAreaInsetKey.self] = newValue }
    }
}

struct ExtraTopSafeAreaInset: View {
    @Environment(\.topSafeAreaInset) var topSafeAreaInset: CGFloat

    var body: some View {
        Spacer(minLength: topSafeAreaInset)
    }
}

struct ExtraBottomSafeAreaInset: View {
    @Environment(\.bottomSafeAreaInset) var bottomSafeAreaInset: CGFloat

    var body: some View {
        Spacer(minLength: bottomSafeAreaInset)
    }
}
