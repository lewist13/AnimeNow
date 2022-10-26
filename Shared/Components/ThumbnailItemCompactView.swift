//
//  ThumbnailItemCompactView.swift
//  Anime Now! (iOS)
//
//  Created by ErrorErrorError on 9/22/22.
//

import SwiftUI
import Kingfisher

struct ThumbnailItemCompactView: View {
    let episode: EpisodeRepresentable
    var progress: Double? = nil

    var body: some View {
        GeometryReader { reader in
            HStack(alignment: .center, spacing: 12) {
                KFImage(episode.thumbnail?.link)
                    .resizable()
                    .transaction { $0.animation = nil }
                    .scaledToFill()
                    .frame(height: reader.size.height)
                    .contentShape(Rectangle())
                    .clipped()
                    .cornerRadius(reader.size.height / 8)
                    .aspectRatio(16/9, contentMode: .fit)
                    .overlay(
                        Group {
                            if let progress = progress, progress >= 0.9 {
                                Text("Watched")
                                    .font(.caption.bold())
                                    .foregroundColor(.white)
                                    .padding(8)
                                    .background(Color(white: 0.2))
                                    .clipShape(Capsule())
                                    .padding(8)
                                    .frame(
                                        maxWidth: .infinity,
                                        maxHeight: .infinity,
                                        alignment: .topLeading
                                    )
                            }
                        }
                    )

                VStack(alignment: .leading, spacing: 4) {
                    Spacer()

                    Text(episode.title)
                        .font(.body)
                        .foregroundColor(Color.white)
                        .bold()
                        .lineLimit(1)

                    Text("E\(episode.number)")
                        .font(.footnote)
                        .bold()
                        .foregroundColor(Color.white.opacity(0.85))

                    if let progress = progress, progress < 0.9 {
                        SeekbarView(
                            progress: .constant(progress),
                            padding: 0
                        )
                        .frame(height: 6)
                        .disabled(true)
                        .padding(.vertical, 4)
                    }

                    Spacer()
                }

                Spacer()
            }
        }
        .frame(maxWidth: .infinity)
    }
}

struct EpisodeItemCompactView_Previews: PreviewProvider {
    static var previews: some View {
        ThumbnailItemCompactView(
            episode: Episode.demoEpisodes.first!.asRepresentable(),
            progress: 0.9
        )
        .preferredColorScheme(.dark)
        .frame(height: 100)
    }
}
