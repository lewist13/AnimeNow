//
//  ThumbnailItemBigView.swift
//  Anime Now! (iOS)
//
//  Created by ErrorErrorError on 9/22/22.
//

import SwiftUI
import Kingfisher

struct ThumbnailItemBigView: View {
    enum InputType {
        case episode(image: URL?, name: String, animeName: String?, number: Int, progress: Double?)
        case movie(image: URL?, name: String, progress: Double?)

        var name: String {
            switch self {
            case .episode(_, let name,_,_,_),
                    .movie(_, let name, _):
                return name
            }
        }

        var image: URL? {
            switch self {
            case .episode(let image,_,_,_,_),
                    .movie(let image,_,_):
                return image
            }
        }

        var progress: Double? {
            switch self {
            case .episode(_,_,_,_, let progress),
                    .movie(_,_, let progress):
                return progress
            }
        }
    }

    struct DownloadStatus {
        var state: DownloaderClient.Status? = nil
        var callback: ((Action) -> Void) = { _ in }

        enum Action {
            case download
            case cancel
            case retry
        }
    }

    let type: InputType
    var isFiller = false
    var nowPlaying = false
    var progressSize: CGFloat = 10
    var downloadStatus: DownloadStatus? = nil

    var body: some View {
        GeometryReader { reader in
            FillAspectImage(
                url: type.image
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
                            } else if let progress = type.progress, progress >= 0.9 {
                                Text("Watched")
                            }
                        }
                        .font(.footnote.weight(.heavy))
                        .foregroundColor(nowPlaying ? Color.black : Color.white)
                        .padding(.horizontal, 12)
                        .frame(height: size)
                        .background(nowPlaying ? Color(white: 0.9) :  Color(white: 0.15))
                        .clipShape(Capsule())

                        Spacer()

                        if let downloadStatus {
                            switch downloadStatus.state {
                            case  .some(.pending), .some(.downloading):
                                Circle()
                                    .foregroundColor(.white)
                                    .frame(width: size, height: size)
                                    .overlay(
                                        Group {
                                            if case .downloading(let progress) = downloadStatus.state {
                                                CircularProgressView(progress: progress)
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
                    }

                    Spacer()

                    VStack(alignment: .leading, spacing: 0) {
                        if case .episode(_,_, let animeName, let number, _) = type {
                            HStack(spacing: 2) {
                                Text("E\(number)")
                                if let animeName = animeName {
                                    Text("\u{2022}")
                                    Text(animeName)
                                } else if isFiller {
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
                        }

                        Text(type.name)
                            .multilineTextAlignment(.leading)
                            .lineLimit(1)
                            .font(.title3.weight(.bold))

                        if !nowPlaying, let progress = type.progress, progress < 0.9 {
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
            type: .episode(
                image: episode.thumbnail?.link,
                name: episode.title,
                animeName: nil,
                number: episode.number,
                progress: 0.5
            ),
            isFiller: true,
            downloadStatus: .init()
        )
        .frame(height: 200)
    }
}
