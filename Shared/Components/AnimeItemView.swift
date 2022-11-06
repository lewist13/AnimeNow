//
//  AnimeItemView.swift
//  Anime Now! (iOS)
//
//  Created by ErrorErrorError on 9/4/22.
//

import SwiftUI
import Kingfisher

struct AnimeItemView: View {
    let anime: any AnimeRepresentable

    var body: some View {
        GeometryReader { reader in
            FillAspectImage(
                url: anime.posterImage.largest?.link
            )
            .overlay(
                LinearGradient(
                    stops: [
                        .init(color: .clear, location: 0.4),
                        .init(color: .black.opacity(0.75), location: 1.0)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .overlay(
                VStack {
                    Spacer()
                    Text(anime.title)
                        .font(.callout.bold())
                        .foregroundColor(.white)
                        .lineLimit(2)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                        .padding(.vertical, 8)
                        .frame(maxWidth: .infinity)
                }
                    .frame(
                        maxWidth: .infinity,
                        maxHeight: .infinity
                    )
            )
        }
        .aspectRatio(2/3, contentMode: .fit)
        .cornerRadius(12)
    }
}

struct TrendingAnimeItemView_Previews: PreviewProvider {
    @Namespace static var namespace

    static var previews: some View {
        AnimeItemView(
            anime: Anime.narutoShippuden
        )
        .frame(height: 250)
        .preferredColorScheme(.dark)
    }
}
