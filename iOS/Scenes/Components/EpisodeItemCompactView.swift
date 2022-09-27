//
//  EpisodeItemCompactView.swift
//  Anime Now! (iOS)
//
//  Created by Erik Bautista on 9/22/22.
//

import SwiftUI
import Kingfisher

struct EpisodeItemCompactView: View {
    let episode: Episode

    var body: some View {
        let height = 84.0
        let width = (height * 16.0) / 9.0
        HStack(alignment: .center, spacing: 12) {
            KFImage(episode.thumbnail.largest?.link)
                .resizable()
                .aspectRatio(16/9, contentMode: .fill)
                .frame(width: width, height: height)
                .cornerRadius(height / 8)

            VStack(alignment: .leading, spacing: 4) {
                Text(episode.name)
                    .font(.body)
                    .foregroundColor(Color.white)
                    .bold()
                    .lineLimit(2)

                Text(
                    "E\(episode.number)" +
                    (episode.length != nil ? " \u{2022} \(episode.lengthFormatted)" : "")
                )
                    .font(.footnote)
                    .bold()
                    .foregroundColor(Color.white.opacity(0.85))

            }

            Spacer()
        }
    }
}

struct EpisodeItemCompactView_Previews: PreviewProvider {
    static var previews: some View {
        EpisodeItemCompactView(
            episode: .demoEpisodes.first!
        )
        .preferredColorScheme(.dark)
    }
}
