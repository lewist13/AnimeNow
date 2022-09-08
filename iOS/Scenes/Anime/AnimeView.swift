//
//  AnimeView.swift
//  Anime Now!
//
//  Created Erik Bautista on 9/6/22.
//  Copyright © 2022. All rights reserved.
//

import SwiftUI
import ComposableArchitecture
import Kingfisher

struct AnimeView: View {
    let store: Store<AnimeCore.State, AnimeCore.Action>

    var body: some View {
        WithViewStore(
            store
        ) { viewStore in
            ScrollView {
                topContainer(viewStore.state)
                infoContainer(viewStore.state)
            }
            .edgesIgnoringSafeArea(.top)
        }
    }
}

extension AnimeView {
    @ViewBuilder
    func topContainer(_ anime: AnimeCore.State) -> some View {
        ZStack(alignment: .bottomLeading) {
            KFImage(anime.posterImage)
                .setProcessor(BlurImageProcessor(blurRadius: 0.5))
                .cacheMemoryOnly()
                .fade(duration: 0.5)
                .resizable()
                .scaledToFill()
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
                Text(anime.title)
                    .font(.largeTitle)
                    .bold()
                    .foregroundColor(.white)

                HStack(alignment: .top, spacing: 4) {
                    ForEach(anime.categories, id: \.self) { category in
                        Text(category)
                            .font(.footnote)
                            .bold()
                            .foregroundColor(.white.opacity(0.8))
                        if anime.categories.last != category {
                            Text("\u{2022}")
                                .font(.footnote)
                                .fontWeight(.black)
                                .foregroundColor(.white.opacity(0.8))
                        }
                    }
                }

                Button {
                    print("Play button clicked for \(anime.title)")
                } label: {
                    HStack {
                        Image(systemName: "play.fill")
                        Text("Play Show")
                    }
                }
                .buttonStyle(PlayButton())
                .padding(.top, 16)
            }
            .padding()
        }
    }

    @ViewBuilder
    func infoContainer(_ anime: AnimeCore.State) -> some View {
        
    }

    @ViewBuilder
    func episodesContainer(_ anime: AnimeCore.State) -> some View {

    }
}

extension AnimeView {
    struct PlayButton: ButtonStyle {
        func makeBody(configuration: Configuration) -> some View {
            configuration.label
                .font(.system(size: 15).weight(.heavy))
                .padding()
                .background(Color.white)
                .foregroundColor(.black)
                .clipShape(Capsule())
                .scaleEffect(configuration.isPressed ? 1.2 : 1)
                .animation(.easeOut(duration: 0.2), value: configuration.isPressed)
        }
    }
}

struct AnimeView_Previews: PreviewProvider {
    static var previews: some View {
        AnimeView(
            store: .init(
                initialState: .attackOnTitan,
                reducer: AnimeCore.reducer,
                environment: .init()
            )
        )
        .preferredColorScheme(.dark)
    }
}
