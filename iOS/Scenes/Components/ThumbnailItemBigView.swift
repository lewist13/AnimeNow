//
//  ThumbnailItemBigView.swift
//  Anime Now! (iOS)
//
//  Created by Erik Bautista on 9/22/22.
//

import SwiftUI
import Kingfisher

struct ThumbnailItemBigView: View {
    enum InputType {
        case episode(image: URL?, name: String, number: Int, progress: Double?)
        case movie(image: URL?, name: String, progress: Double?)

        var name: String {
            switch self {
            case .episode(_, let name, _, _),
                    .movie(_, let name, _):
                return name
            }
        }

        var image: URL? {
            switch self {
            case .episode(let image,_,_,_),
                    .movie(let image,_,_):
                return image
            }
        }

        var progress: Double? {
            switch self {
            case .episode(_,_,_, let progress),
                    .movie(_,_, let progress):
                return progress
            }
        }
    }

    let type: InputType
    var watched: Bool = false

    var body: some View {
        GeometryReader { reader in
            ZStack(alignment: .bottomLeading) {
                KFImage(type.image)
                    .placeholder {
                        imageShimmeringView
                    }
                    .fade(duration: 0.5)
                    .resizable()
                    .scaledToFill()
                    .frame(
                        width: reader.size.width,
                        height: reader.size.height,
                        alignment: .center
                    )
                    .overlay(
                        LinearGradient(
                            colors: [
                                .clear,
                                .clear,
                                .black.opacity(0.95)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )

                VStack(alignment: .leading, spacing: 0) {
                    Text(type.name)
                        .multilineTextAlignment(.leading)
                        .lineLimit(2)
                        .font(.title2.bold())

                    if case .episode(_,_,let number, let progress) = type {
                        Text("E\(number)")
                            .font(.callout.bold())
                            .foregroundColor(.white.opacity(0.9))
                            .padding(.bottom, progress != nil && !watched ? 6 : 0)
                    }

                    if let progress = type.progress, !watched {
                        SeekbarView(
                            progress: .constant(progress),
                            padding: 0
                        )
                            .disabled(true)
                            .frame(height: 10)
                    }
                }
                .foregroundColor(Color.white)
                .padding()

                if watched {
                    Text("Watched")
                        .font(.footnote.bold())
                        .foregroundColor(Color.white)
                        .padding(12)
                        .background(BlurView(style: .systemUltraThinMaterialDark))
                        .clipShape(Capsule())
                        .frame(
                            maxWidth: .infinity,
                            maxHeight: .infinity,
                            alignment: .topTrailing
                        )
                        .padding()
                }
            }
        }
        .aspectRatio(16/9, contentMode: .fill)
        .cornerRadius(16)
        .clipped()
    }
}

extension ThumbnailItemBigView {
    @ViewBuilder
    private var imageShimmeringView: some View {
        RoundedRectangle(cornerRadius: 16)
            .foregroundColor(Color.gray.opacity(0.2))
            .shimmering()
    }
}

struct EpisodeItemBigView_Previews: PreviewProvider {
    static var previews: some View {
        let episode = Episode.demoEpisodes.first!
        ThumbnailItemBigView(
            type: .episode(
                image: episode.thumbnail.largest?.link,
                name: episode.name,
                number: episode.number,
                progress: 0.5
            )
        )
         .frame(width: 300)
        .frame(height: 0)
    }
}
