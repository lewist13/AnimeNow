////  ScaledOnHoverModifier.swift
//  Anime Now!
//
//  Created by ErrorErrorError on 11/5/22.
//  
//

import SwiftUI

struct ScaledOnHover: ViewModifier {
    let factor: CGFloat
    @State private var isHovered = false

    func body(content: Content) -> some View {
        content
            .scaleEffect(isHovered ? factor : 1)
            .animation(.easeOut(duration: 0.2), value: isHovered)
            .onHover { isHovered in
                withAnimation {
                    self.isHovered = isHovered
                }
            }
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { event in
                        guard !isHovered else { return }
                        withAnimation {
                            self.isHovered = true
                        }
                    }
                    .onEnded { event in
                        self.isHovered = false
                    }
                )
    }
}

extension View {
    func scaleOnHover(factor: CGFloat = 1.1) -> some View {
        self.modifier(ScaledOnHover(factor: factor))
    }
}
