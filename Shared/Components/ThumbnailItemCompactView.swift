//
//  ThumbnailItemCompactView.swift
//  Anime Now! (iOS)
//
//  Created by ErrorErrorError on 9/22/22.
//

import SwiftUI
import Kingfisher

struct ThumbnailItemCompactView: View {
    let episode: Episode
    var progress: Double? = nil

    var body: some View {
        GeometryReader { reader in
            HStack(alignment: .center, spacing: 12) {
                KFImage(episode.thumbnail.largest?.link)
                    .resizable()
                    .scaledToFill()
                    .frame(
                        width: (reader.size.height * 16) / 9,
                        height: reader.size.height
                    )
                    .contentShape(Rectangle())
                    .clipped()
                    .cornerRadius(reader.size.height / 8)

                VStack(alignment: .leading, spacing: 4) {
                    Spacer()
                    Text(episode.name)
                        .font(.body)
                        .foregroundColor(Color.white)
                        .bold()
                        .lineLimit(1)

                    Text(
                        "E\(episode.number)" +
                        (episode.length != nil ? " \u{2022} \(episode.lengthFormatted)" : "")
                    )
                        .font(.footnote)
                        .bold()
                        .foregroundColor(Color.white.opacity(0.85))

                    Spacer()

                    if let progress = progress, progress < 0.9 {
                        SeekbarView(
                            progress: .constant(progress),
                            padding: 0
                        )
                        .frame(height: 6)
                        .disabled(true)
                        .padding(.vertical, 4)
                    }
                }

                Spacer()
            }
        }
    }
}

struct EpisodeItemCompactView_Previews: PreviewProvider {
    static var previews: some View {
        ThumbnailItemCompactView(
            episode: .demoEpisodes.first!
        )
        .preferredColorScheme(.dark)
        .frame(height: 100)
    }
}
