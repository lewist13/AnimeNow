//
//  TrendingAnimeItemView.swift
//  Anime Now! (iOS)
//
//  Created by Erik Bautista on 9/4/22.
//

import SwiftUI
import Kingfisher

struct TrendingAnimeItemView: View {
    let anime: Anime

    @ScaledMetric var size: CGFloat = 1.0

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            KFImage(anime.posterImage)
                .setProcessor(BlurImageProcessor.init(blurRadius: 0.5))
                .cacheMemoryOnly()
                .fade(duration: 0.5)
                .resizable(capInsets: .init(), resizingMode: .stretch)
                .shadow(color: .black.opacity(0.2), radius: 14, x: 0, y: 0)
                .overlay(
                    LinearGradient(
                        colors: [
                            .clear,
                            .clear,
                            .black
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )

            Text(anime.title)
                .font(.body)
                .bold()
                .multilineTextAlignment(.leading)
                .foregroundColor(.white)
                .padding(12)
        }
        .cornerRadius(12)
        .frame(width: 150 * size, height: 225 * size)
    }
}

struct TrendingAnimeItemView_Previews: PreviewProvider {
    static var previews: some View {
        TrendingAnimeItemView(
            anime: .narutoShippuden
        )
    }
}
