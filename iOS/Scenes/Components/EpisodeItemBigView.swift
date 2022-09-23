//
//  EpisodeItemBigView.swift
//  Anime Now! (iOS)
//
//  Created by Erik Bautista on 9/22/22.
//

import SwiftUI
import Kingfisher

struct EpisodeItemBigView: View {
    let episode: Episode

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            KFImage(episode.thumbnail.largest?.link)
                .placeholder {
                    episodeShimmeringView
                }
                .fade(duration: 0.5)
                .resizable()
                .episodeFrame()
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

            VStack(alignment: .leading, spacing: 4) {
                Text(episode.name)
                    .font(.title2.bold())
                HStack {
                    Text("E\(episode.number)" + (episode.length != nil ? " \u{2022} \(episode.lengthFormatted)" : ""))
                        .font(.callout.bold())
                }
            }
            .padding()
        }
    }
}

extension EpisodeItemBigView {
    @ViewBuilder
    private var episodeShimmeringView: some View {
        RoundedRectangle(cornerRadius: 16)
            .episodeFrame()
            .foregroundColor(Color.gray.opacity(0.2))
            .shimmering()
    }
}

extension View {
    fileprivate func episodeFrame() -> some View {
        self
            .aspectRatio(16/9, contentMode: .fill)
            .frame(maxWidth: .infinity, alignment: .center)
            .cornerRadius(16)
    }
}

struct EpisodeItemBigView_Previews: PreviewProvider {
    static var previews: some View {
        EpisodeItemBigView(
            episode: .demoEpisodes.first!
        )
    }
}
