//
//  VideoPlayerClient+Live.swift
//  Anime Now!
//
//  Created by Erik Bautista on 9/14/22.
//

import Foundation
import AVFoundation
import ComposableArchitecture
import Combine

extension VideoPlayerClient {
    static let live: Self = {
        var avPlayer: AVPlayer? = nil

        return Self.init(
            play: { url in
                .run { subscriber in
                    if avPlayer == nil {
                        avPlayer = .init(url: url)
                    } else {
                        avPlayer?.replaceCurrentItem(with: .init(url: url))
                    }

                    avPlayer?.addPeriodicTimeObserver(forInterval: .init(value: 10, timescale: 10), queue: .none, using: { time in
                        subscriber.send(.updatedPeriodicTime(time))
                    })

                    avPlayer?.play()

                    return AnyCancellable {
                        avPlayer?.pause()
                        avPlayer = nil
                    }
                }
            },
            resume: {
                .fireAndForget {
                    avPlayer?.play()
                }
            },
            pause: {
                .fireAndForget {
                    avPlayer?.pause()
                }
            },
            stop: {
                .fireAndForget {
                    avPlayer?.pause()
                    avPlayer = nil
                }
            },
            seek: { time in
                .fireAndForget {
                    avPlayer?.seek(to: time)
                }
            }
        )
    }()
}
