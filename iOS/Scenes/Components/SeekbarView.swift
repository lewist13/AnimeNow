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
    var preloaded: Double = 0.0
    var onEditingCallback: EditingChanged?

    @State var isDragging = false

    let scaled = 1.25

    var body: some View {
        GeometryReader { reader in
            ZStack(alignment: .leading) {
                // Background
                BlurView(style: .systemThinMaterialDark)

                // Preloaded
                Color.gray
                    .frame(width: preloaded * reader.size.width)

                // Progress
                Color.white
                    .frame(
                        width: progress * reader.size.width,
                        alignment: .leading
                    )
            }
                .frame(
                    width: reader.size.width,
                    height: reader.size.height * (isDragging ? scaled : 1)
                )
                .clipShape(Capsule())
                .offset(
                    y: isDragging ? -(reader.size.height/10 * scaled) : 0
                )
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
            SeekbarView(progress: $progress, preloaded: 0.0)
        }
    }

    static var previews: some View {
        BindingProvider()
            .frame(width: 300, height: 10)
    }
}
