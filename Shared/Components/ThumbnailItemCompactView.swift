//
//  ThumbnailItemCompactView.swift
//  Anime Now! (iOS)
//
//  Created by ErrorErrorError on 9/22/22.
//

import SwiftUI
import Kingfisher

struct ThumbnailItemCompactView: View {
    let episode: any EpisodeRepresentable
    var progress: Double? = nil

    var downloadState: ThumbnailItemBigView.DownloadState?

    var body: some View {
        GeometryReader { reader in
            HStack(alignment: .center, spacing: 12) {
                FillAspectImage(
                    url: episode.thumbnail?.link
                )
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

                    HStack(spacing: 2) {
                        Text("E\(episode.number)")

                        if episode.isFiller {
                            Text("\u{2022}")
                            Text("Filler")
                                .font(.caption2.weight(.bold))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 3)
                                .background(Color(white: 0.2))
                                .clipShape(Capsule())
                        }
                    }
                    .font(.footnote.bold())
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

                Group {
                    if let downloadState {
                        switch downloadState {
                        case .empty(let callback):
                            Button {
                                callback()
                            } label: {
                                Image(systemName: "arrow.down.to.line")
                                    .font(.body.bold())
                                    .foregroundColor(.gray)
                            }
                            .buttonStyle(.plain)
                        case .downloading(let percentage):
                            CircularProgressView(progress: percentage)
                                .frame(width: 16, height: 16)
                                .padding(4)
                                .background(Color.white)
                                .clipShape(Circle())

                        case .downloaded:
                            Image(systemName: "checkmark")
                                .font(.callout.weight(.bold))
                                .foregroundColor(.white)
                                .padding(4)
                                .background(Color.green)
                                .clipShape(Circle())

                        case .error:
                            Image(systemName: "exclamationmark")
                                .font(.callout.weight(.bold))
                                .foregroundColor(.white)
                                .padding(4)
                                .background(Color.red)
                                .clipShape(Circle())
                        }
                    }
                }
                .frame(maxWidth: 24, maxHeight: 24)
            }
            .background(Color.black)
            .cornerRadius(reader.size.height / 8)
        }
        .frame(maxWidth: .infinity)
    }
}

struct EpisodeItemCompactView_Previews: PreviewProvider {
    static var previews: some View {
        ThumbnailItemCompactView(
            episode: Episode.demoEpisodes[1].asRepresentable(),
            progress: 0.9
        )
        .preferredColorScheme(.dark)
        .frame(height: 100)
    }
}
