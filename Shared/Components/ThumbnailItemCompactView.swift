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
    var downloadStatus: ThumbnailItemBigView.DownloadStatus? = nil

    var body: some View {
        HStack(
            alignment: .center,
            spacing: 12
        ) {
            FillAspectImage(
                url: episode.thumbnail?.link
            )
            .aspectRatio(16/9, contentMode: .fit)
            .cornerRadius(12)
            .overlay(
                Group {
                    if let progress, progress >= 0.9 {
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
            .fixedSize(horizontal: true, vertical: false)

            VStack(alignment: .leading, spacing: 4) {
                Spacer()

                Text(episode.title)
                    .font(.body)
                    .foregroundColor(Color.white)
                    .bold()
                    .lineLimit(2)

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

                if let progress, progress < 0.9 {
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

            if let downloadStatus {
                Group {
                    switch downloadStatus.state {
                    case .some(.pending), .some(.downloading):
                        Group {
                            if case .downloading(let percentage) = downloadStatus.state {
                                CircularProgressView(progress: percentage)
                            } else {
                                CircularProgressView(progress: 0.0)
                            }
                        }
                        .foregroundColor(.gray)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            downloadStatus.callback(.cancel)
                        }

                    case .some(.downloaded):
                        Image(systemName: "checkmark")
                            .font(.callout.weight(.bold))
                            .foregroundColor(.white)
                            .padding(4)
                            .background(Color.green)
                            .clipShape(Circle())

                    case .some(.failed):
                        Image(systemName: "exclamationmark")
                            .font(.callout.weight(.bold))
                            .foregroundColor(.white)
                            .padding(4)
                            .background(Color.red)
                            .clipShape(Circle())

                    case .none:
                        Button {
                            downloadStatus.callback(.download)
                        } label: {
                            Image(systemName: "arrow.down.to.line")
                                .font(.body.bold())
                                .foregroundColor(.gray)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .frame(maxWidth: 24, maxHeight: 24)
                .animation(.linear, value: downloadStatus.state)
            }
        }
        .background(Color.black)
        .frame(maxWidth: .infinity)
    }
}

struct EpisodeItemCompactView_Previews: PreviewProvider {
    static var previews: some View {
        ThumbnailItemCompactView(
            episode: Episode(
                title: "Testtiyhhhhhhhhhhhhhhhhhhhhhhhhhh",
                number: 1,
                description: " hahahahahah",
                thumbnail: nil,
                isFiller: false
            ),
            progress: 0.9,
            downloadStatus: .init()
        )
        .preferredColorScheme(.dark)
        .frame(height: 100)
    }
}
