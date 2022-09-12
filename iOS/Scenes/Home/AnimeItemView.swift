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

    var namespace: Namespace.ID

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            KFImage(anime.posterImage.largest?.link)
                .cacheMemoryOnly()
                .setProcessors([RoundCornerImageProcessor(cornerRadius: 12)])
                .fade(duration: 0.5)
                .resizable()
                .shadow(color: .black.opacity(0.2), radius: 14, x: 0, y: 0)
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
//                .matchedGeometryEffect(id: "\(anime.id)-image", in: namespace, isSource: true)

            Text(anime.title)
                .font(.system(size: 13))
                .bold()
                .multilineTextAlignment(.leading)
                .foregroundColor(.white)
                .padding(12)
//                .matchedGeometryEffect(id: "\(anime.id)-name", in: namespace, isSource: true)
        }
        .cornerRadius(12)
        .aspectRatio(2/3, contentMode: .fit)
    }
}

struct TrendingAnimeItemView_Previews: PreviewProvider {
    @Namespace static var namespace

    static var previews: some View {
        AnimeItemView(
            anime: .narutoShippuden,
            namespace: namespace
        )
        .frame(height: 200)
    }
}
