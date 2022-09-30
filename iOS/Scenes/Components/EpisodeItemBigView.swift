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
    var progress: Double?

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            KFImage(episode.thumbnail.largest?.link)
                .placeholder {
                    imageShimmeringView
                }
                .fade(duration: 0.5)
                .resizable()
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

            VStack.init(alignment: .leading, spacing: 0) {
                Text(episode.name)
                    .multilineTextAlignment(.leading)
                    .lineLimit(2)
                    .font(.title2.bold())
                Text(episode.episodeNumberLengthFormat)
                    .font(.callout.bold())
                    .foregroundColor(.white.opacity(0.9))
                    .padding(.bottom, progress == nil ? 0 : 6)

                if let progress = progress {
                    SeekbarView(progress: .constant(progress))
                        .disabled(true)
                        .frame(height: 10)
                }
            }
            .foregroundColor(Color.white)
            .padding()
        }
        .episodeFrame()
    }
}

extension EpisodeItemBigView {
    @ViewBuilder
    private var imageShimmeringView: some View {
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
            .cornerRadius(16)
    }
}

struct EpisodeItemBigView_Previews: PreviewProvider {
    static var previews: some View {
        EpisodeItemBigView(
            episode: .demoEpisodes.first!,
            progress: 0.5
        )
        .preferredColorScheme(.dark)
        .frame(maxWidth: .infinity)
        .frame(height: 0)
    }
}
