//
//  FillAspectImage.swift
//
//
//  Created by ErrorErrorError on 10/25/22.
//  
//

import SwiftUI
import Kingfisher

public struct FillAspectImage: View {
    let url: URL?

    @State private var finishedLoading: Bool

    public init(url: URL?) {
        self.url = url
        self._finishedLoading = .init(initialValue: ImageCache.default.isCached(forKey: url?.absoluteString ?? ""))
    }

    public var body: some View {
        GeometryReader { proxy in
            KFImage.url(url)
                .onSuccess { image in
                    finishedLoading = true
                }
                .onFailure { _ in
                    finishedLoading = true
                }
                .resizable()
                .transaction { $0.animation = nil }
                .scaledToFill()
                .transition(.opacity)
                .opacity(finishedLoading ? 1.0 : 0.0)
                .background(Color(white: 0.05))
                .frame(
                    width: proxy.size.width,
                    height: proxy.size.height,
                    alignment: .center
                )
                .contentShape(Rectangle())
                .clipped()
                .animation(.easeInOut(duration: 0.5), value: finishedLoading)
        }
    }
}
