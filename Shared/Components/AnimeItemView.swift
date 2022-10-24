//
//  AnimeItemView.swift
//  Anime Now! (iOS)
//
//  Created by ErrorErrorError on 9/4/22.
//

import SwiftUI
import Kingfisher

struct AnimeItemView: View {
    let anime: Anime

    var body: some View {
        GeometryReader { reader in
            KFImage(anime.posterImage.largest?.link)
                .fade(duration: 0.5)
                .resizable()
                .scaledToFill()
                .frame(
                    width: reader.size.width,
                    height: reader.size.height,
                    alignment: .center
                )
                .contentShape(Rectangle())
                .clipped()
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
//                        if let year = anime.releaseYear {
//                            Text(year.description)
//                                .font(.caption2.bold().monospacedDigit())
//                                .foregroundColor(.white)
//                                .padding(.horizontal, 10)
//                                .padding(.vertical, 6)
////                    .background(BlurView(style: .systemThinMaterialDark))
//                                .clipShape(Capsule())
//                                .padding(12)
//                                .frame(
//                                    maxWidth: .infinity,
//                                    maxHeight: .infinity,
//                                    alignment: .topTrailing
//                                )
//                        }

                        Spacer()
                        Text(anime.title)
                            .font(.callout.bold())
                            .foregroundColor(.white)
                            .lineLimit(2)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                            .padding(.vertical, 4)
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
            anime: .narutoShippuden
        )
        .frame(height: 250)
        .preferredColorScheme(.dark)
    }
}
