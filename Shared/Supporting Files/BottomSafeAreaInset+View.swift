//
//  BottomSafeAreaInset+View.swift
//  Anime Now!
//
//  Created by ErrorErrorError on 10/19/22.
//  From https://github.com/FiveStarsBlog/CodeSamples/blob/main/SafeAreaInset/content.swift

import SwiftUI

#if os(iOS)
extension View {
    @ViewBuilder
    func bottomSafeAreaInset<OverlayContent: View>(
        _ overlayContent: OverlayContent
    ) -> some View {
        if #available(iOS 15.0, *) {
            self.safeAreaInset(edge: .bottom, spacing: 0, content: { overlayContent }) // 👈🏻 1
        } else {
            self.modifier(BottomInsetViewModifier(overlayContent: overlayContent))
        }
    }
}

#endif
extension View {
    func readHeight(onChange: @escaping (CGFloat) -> Void) -> some View {
        background(
            GeometryReader { geometryProxy in
                Spacer()
                    .preference(
                        key: HeightPreferenceKey.self,
                        value: geometryProxy.size.height
                    )
            }
        )
        .onPreferenceChange(HeightPreferenceKey.self, perform: onChange)
    }
}

private struct HeightPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = .zero
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {}
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
                    .readHeight {
                        overlayContentHeight = $0
                    }
                    .padding(.bottom, ancestorBottomSafeAreaInset)
                ,
                alignment: .bottom
            )
    }
}

struct BottomSafeAreaInsetKey: EnvironmentKey {
    static var defaultValue: CGFloat = 0
}

extension EnvironmentValues {
    var bottomSafeAreaInset: CGFloat {
        get { self[BottomSafeAreaInsetKey.self] }
        set { self[BottomSafeAreaInsetKey.self] = newValue }
    }
}

struct ExtraBottomSafeAreaInset: View {
    @Environment(\.bottomSafeAreaInset) var bottomSafeAreaInset: CGFloat
    
    var body: some View {
        Spacer(minLength: bottomSafeAreaInset)
    }
}
