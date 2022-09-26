//
//  AnimeItemView.swift
//  Anime Now! (iOS)
//
//  Created by Erik Bautista on 9/4/22.
//

import SwiftUI
import Kingfisher

struct AnimeItemView: View {
    let anime: Anime

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            KFImage(anime.posterImage.largest?.link)
                .fade(duration: 0.5)
                .resizable()
                .overlay(
                    LinearGradient(
                        colors: [
                            .clear,
                            .clear,
                            .black.opacity(0.85)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )

            Text(anime.title)
                .font(.system(size: 16).weight(.bold))
                .multilineTextAlignment(.leading)
                .foregroundColor(.white)
                .padding(12)
        }
        .aspectRatio(2/3, contentMode: .fit)
        .cornerRadius(12)
    }
}

struct TrendingAnimeItemView_Previews: PreviewProvider {
    @Namespace static var namespace

    static var previews: some View {
        AnimeItemView(
            anime: .narutoShippuden
        )
        .frame(height: 200)
    }
}
