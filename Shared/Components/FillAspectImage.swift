//  FillAspectImage.swift
//  Anime Now!
//
//  Created by ErrorErrorError on 10/25/22.
//  
//

import SwiftUI
import Kingfisher

struct FillAspectImage: View {
    let url: URL?

    @State private var loaded = false

    var body: some View {
        GeometryReader { proxy in
            KFImage.url(url)
                .onSuccess { _ in loaded = true }
                .onFailure { _ in loaded = true }
                .resizable()
                .scaledToFill()
                .transaction { $0.animation = nil }
                .opacity(loaded ? 1.0 : 0)
                .background(Color(white: 0.05))
                .frame(
                    width: proxy.size.width,
                    height: proxy.size.height,
                    alignment: .center
                )
                .contentShape(Rectangle())
                .clipped()
                .transition(.opacity)
                .animation(.linear, value: loaded)
        }
    }
}
