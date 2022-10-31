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

    var body: some View {
        GeometryReader { proxy in
            KFImage.url(url)
                .fade(duration: 0.5)
                .configure { $0.resizable() }
                .scaledToFill()
                .background(Color(white: 0.05))
                .frame(
                    width: proxy.size.width,
                    height: proxy.size.height,
                    alignment: .center
                )
                .contentShape(Rectangle())
                .clipped()
        }
    }
}
