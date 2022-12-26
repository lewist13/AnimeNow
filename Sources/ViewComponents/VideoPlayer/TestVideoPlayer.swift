////  TestVideoPlayer.swift
//  Anime Now!
//
//  Created by ErrorErrorError on 10/26/22.
//  
//

import SwiftUI

struct TestVideoPlayer: View {

    var body: some View {
        VideoPlayer(
            player: .init()
        )
        .onAppear {
        }
        .preferredColorScheme(.dark)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
