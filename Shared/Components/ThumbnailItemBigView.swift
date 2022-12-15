//
//  ThumbnailItemBigView.swift
//  Anime Now! (iOS)
//
//  Created by ErrorErrorError on 9/22/22.
//

import SwiftUI
import Kingfisher

struct ThumbnailItemBigView: View {
    struct DownloadStatus {
        var state: DownloaderClient.Status? = nil
        var callback: ((Action) -> Void) = { _ in }

        enum Action {
            case download
            case cancel
            case retry
        }
    }

    let episode: any EpisodeRepresentable
    var animeTitle: String? = nil
    var progress: Double? = nil
    var nowPlaying = false
    var progressSize: CGFloat = 10
    var downloadStatus: DownloadStatus? = nil

    var body: some View {
        GeometryReader { reader in
            FillAspectImage(
                url: episode.thumbnail?.link
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
                VStack(spacing: 0) {
                    HStack {
                        let size: CGFloat = 34
                        Group {
                            if nowPlaying {
                                Text("Now Playing")
                            } else if let progress, progress >= 0.9 {
                                Text("Watched")
                            }
                        }
                        .font(.footnote.weight(.heavy))
                        .foregroundColor(nowPlaying ? Color.black : Color.white)
                        .padding(.horizontal, 12)
                        .frame(height: size)
                        .background(nowPlaying ? Color(white: 0.9) :  Color(white: 0.15))
                        .clipShape(Capsule())
                        .animation(.linear, value: nowPlaying)

                        Spacer()

                        if let downloadStatus {
                            Group {
                                switch downloadStatus.state {
                                case .some(.pending), .some(.downloading):
                                    Circle()
                                        .foregroundColor(.white)
                                        .frame(width: size, height: size)
                                        .overlay(
                                            Group {
                                                if case .downloading(let progress) = downloadStatus.state {
                                                    CircularProgressView(progress: progress)
                                                        .animation(.linear, value: progress)
                                                } else {
                                                    CircularProgressView(progress: 0.0)
                                                }
                                            }
                                                .frame(width: 20, height: 20)
                                                .foregroundColor(.black)
                                        )
                                        .contentShape(Rectangle())
                                        .onTapGesture {
                                            downloadStatus.callback(.cancel)
                                        }

                                case .some(.downloaded):
                                    Image(systemName: "checkmark")
                                        .font(.callout.weight(.black))
                                        .foregroundColor(.white)
                                        .frame(width: size, height: size)
                                        .background(Color.green)
                                        .clipShape(Circle())

                                case .some(.failed):
                                    Image(systemName: "exclamationmark")
                                        .font(.callout.weight(.black))
                                        .foregroundColor(.white)
                                        .frame(width: size, height: size)
                                        .background(Color.red)
                                        .clipShape(Circle())
                                        .contentShape(Rectangle())
                                        .onTapGesture {
                                            downloadStatus.callback(.retry)
                                        }

                                case .none:
                                    Button {
                                        downloadStatus.callback(.download)
                                    } label: {
                                        Image(systemName: "arrow.down.to.line")
                                            .font(.callout.weight(.bold))
                                            .foregroundColor(.black)
                                            .frame(width: size, height: size)
                                            .background(Color.white)
                                            .clipShape(Circle())
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .animation(.easeInOut, value: downloadStatus.state)
                        }
                    }

                    Spacer()

                    VStack(alignment: .leading, spacing: 0) {
                        HStack(spacing: 2) {
                            Text("E\(episode.number)")
                            if let animeTitle {
                                Text("\u{2022}")
                                Text(animeTitle)
                            } else if episode.isFiller {
                                Text("\u{2022}")
                                Text("Filler")
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 3)
                                    .background(Color(white: 0.2))
                                    .clipShape(Capsule())
                            }
                        }
                        .font(.footnote.weight(.bold))
                        .lineLimit(1)
                        .foregroundColor(.init(white: 0.9))

                        Text(episode.title)
                            .multilineTextAlignment(.leading)
                            .lineLimit(1)
                            .font(.title3.weight(.bold))

                        if !nowPlaying, let progress, progress < 0.9 {
                            SeekbarView(
                                progress: .constant(progress),
                                padding: 0
                            )
                            .disabled(true)
                            .frame(height: progressSize)
                            .padding(.top, 4)
                        }
                    }
                    .foregroundColor(Color.white)
                    .frame(
                        maxWidth: .infinity,
                        alignment: .leading
                    )
                }
                    .frame(
                        maxWidth: .infinity,
                        maxHeight: .infinity,
                        alignment: .bottom
                    )
                    .padding(max(reader.size.width, reader.size.height) / 24)
            )
            .cornerRadius(max(reader.size.width, reader.size.height) / 16)
            .transition(.opacity)
        }
        .aspectRatio(16/9, contentMode: .fit)
        .clipped()
    }
}

struct EpisodeItemBigView_Previews: PreviewProvider {
    static var previews: some View {
        let episode = Episode.demoEpisodes.first!
        ThumbnailItemBigView(
            episode: episode,
            progress: 0.5,
            downloadStatus: .init()
        )
        .frame(height: 200)
    }
}
