////  TestVideoPlayer.swift
//  Anime Now!
//
//  Created by ErrorErrorError on 10/26/22.
//  
//

import SwiftUI

struct TestVideoPlayer: View {
    @State var action: VideoPlayer.Action?
    @State var url: URL?

    var body: some View {
        VideoPlayer(
            item: url == nil ? nil : .init(url: url!, title: "", animeTitle: ""),
            action: $action
        )
        .onStatusChanged {
            print("Status: \($0)")
        }
        .onDurationChanged {
            print("Duration: \($0)")
        }
        .onProgressChanged {
            print("Progress: \($0)")
        }
        .onPlayedToTheEnd {
            print("Finished playing video")
        }
        .onBufferChanged {
            print("Buffer: \($0)")
        }
        .onPictureInPictureStatusChanged {
            print("Picture in Picture: \($0)")
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                self.url = URL(string: "https://test-streams.mux.dev/x36xhzz/x36xhzz.m3u8")
            }
        }
        .preferredColorScheme(.dark)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
