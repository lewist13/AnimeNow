//
//  SeekbarView.swift
//  Anime Now! (iOS)
//
//  Created by Erik Bautista on 9/22/22.
//

import SwiftUI

struct SeekbarView: View {

    typealias EditingChanged = (Bool) -> Void

    @Binding var progress: Double
    var buffered = Double.zero

    var padding: Double = 8
    var onEditingCallback: EditingChanged?

    @State var isDragging = false

    var body: some View {
        GeometryReader { reader in
            let scaled = padding / 2

            ZStack {
                ZStack(alignment: .leading) {
                    // Background

                    Color.white.opacity(0.15)

                    Color.gray.opacity(0.25)
                        .frame(
                            width: buffered * reader.size.width,
                            alignment: .leading
                        )

                    // Progress

                    Color.white
                        .frame(
                            width: progress * reader.size.width,
                            alignment: .leading
                        )
                }
                .frame(
                    width: reader.size.width,
                    height: reader.size.height - padding * 2 + (isDragging ? scaled : 0)
                )
                .clipShape(Capsule())
            }
            .frame(width: reader.size.width, height: reader.size.height)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(
                    minimumDistance: 0
                )
                .onChanged({ value in
                    if !isDragging {
                        isDragging = true
                        onEditingCallback?(true)
                    }
                    
                    let locationX = value.location.x
                    let percentage = locationX / reader.size.width
                    progress = max(0, min(1.0, percentage))
                })
                .onEnded({ value in
                    onEditingCallback?(false)
                    isDragging = false
                })
            )
            .animation(.spring(response: 0.3), value: isDragging)
        }
    }
}

struct SeekbarView_Previews: PreviewProvider {
    struct BindingProvider: View {
        @State var progress = 0.25

        var body: some View {
            SeekbarView(progress: $progress, buffered: 0.5)
        }
    }

    static var previews: some View {
        BindingProvider()
            .frame(width: 300, height: 28)
            .preferredColorScheme(.dark)
    }
}
