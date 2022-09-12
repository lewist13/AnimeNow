//
//  AnimeDetailView.swift
//  Anime Now!
//
//  Created Erik Bautista on 9/6/22.
//  Copyright © 2022. All rights reserved.
//

import SwiftUI
import ComposableArchitecture
import Kingfisher

struct AnimeDetailView: View {
    let store: Store<AnimeDetailCore.State, AnimeDetailCore.Action>
    var namespace: Namespace.ID

    @State var expandSummary = false

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            topContainer
            infoContainer
            episodesContainer
        }
        .frame(maxWidth: .infinity)
        .edgesIgnoringSafeArea(.top)
        .overlay(closeButton)
    }
}

// Close button

extension AnimeDetailView {
    @ViewBuilder var closeButton: some View {
        WithViewStore(
            store.stateless
        ) { viewStore in
            Button {
                viewStore.send(
                    .onClose,
                    animation: Animation.spring(
                        response: 0.3,
                        dampingFraction: 0.8
                    )
                )
            } label: {
                closeImage
            }
            .buttonStyle(BlurredButtonStyle())
            .padding(.trailing)
            .onAppear {
                viewStore.send(.onAppear)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
    }

    @ViewBuilder
    private var closeImage: some View {
        Image(
            systemName: "xmark"
        )
        .font(Font.system(size: 14, weight: .black))
        .foregroundColor(Color.white.opacity(0.9))
    }
}

// MARK: - Top Container

extension AnimeDetailView {

    @ViewBuilder
    var topContainer: some View {
        WithViewStore(
            store.scope(state: \.anime)
        ) { viewStore in
            KFImage(viewStore.posterImage.largest?.link)
                .cacheMemoryOnly()
                .fade(duration: 0.5)
                .resizable()
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
                .overlay(
                    VStack(alignment: .leading, spacing: 0) {
                        Text(viewStore.title)
                            .font(.largeTitle)
                            .bold()
                            .foregroundColor(.white)
//                            .matchedGeometryEffect(id: "\(viewStore.id)-name", in: namespace, isSource: false)

                        HStack(alignment: .top, spacing: 4) {
                            ForEach(
                                viewStore.categories,
                                id: \.self
                            ) { category in
                                Text(category)
                                    .font(.footnote)
                                    .bold()
                                    .foregroundColor(.white.opacity(0.8))
                                if viewStore.categories.last != category {
                                    Text("\u{2022}")
                                        .font(.footnote)
                                        .fontWeight(.black)
                                        .foregroundColor(.white.opacity(0.8))
                                }
                            }
                        }

                        Button {
                            print("Play button clicked for \(viewStore.title)")
                        } label: {
                            HStack {
                                Image(systemName: "play.fill")
                                Text("Play Show")
                            }
                        }
                        .buttonStyle(PlayButtonStyle())
                        .padding(.vertical, 12)
                    }
                        .frame(
                            maxWidth: .infinity,
                            maxHeight: .infinity,
                            alignment: .bottomLeading
                        )
                        .padding()
                )
//                .matchedGeometryEffect(id: "\(viewStore.id)-image", in: namespace, isSource: false)
        }
        .aspectRatio(2/3, contentMode: .fill)
    }
}

extension AnimeDetailView {

    @ViewBuilder
    var infoContainer: some View {
        WithViewStore(
            store.scope(state: \.anime)
        ) { anime in
            Section {
                LazyVStack {
                    Text(anime.description)
                        .font(.callout)
                        .foregroundColor(.white)
                        .lineLimit(expandSummary ? nil : 5)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .overlay(
                            Group {
                                if expandSummary {
                                    EmptyView()
                                } else {
                                    LinearGradient(
                                        colors: [
                                            .clear,
                                            .black
                                        ],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                }
                            }
                        )
                }
            } header: {
                HStack(alignment: .center, spacing: 12) {
                    buildSubHeading(title: "Summary")
                    Image(systemName: expandSummary ? "chevron.up" : "chevron.down")
                        .font(Font.system(size: 18, weight: .black))
                        .foregroundColor(Color.white.opacity(0.9))
                    Spacer()
                }
                .padding(.vertical, 6)
                .background(Color.black)
                .onTapGesture {
                    withAnimation(.easeInOut(duration: 0.15)) {
                        expandSummary.toggle()
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal)
    }
}

// MARK: Episodes Container

extension AnimeDetailView {

    @ViewBuilder
    var episodesContainer: some View {
        WithViewStore(
            store.scope(state: \.anime.status)
        ) { statusViewStore in
            if statusViewStore.state != .upcoming {
                WithViewStore(
                    store.scope(state: \.episodes)
                ) { episodesViewStore in
                    Section {
                        if case .loading = episodesViewStore.state {
                            RoundedRectangle(cornerRadius: 16)
                                .episodeFrame()
                                .foregroundColor(Color.gray.opacity(0.2))
                                .shimmering()
                        } else if case let .success(episodes) = episodesViewStore.state {
                            LazyVStack {
                                ForEach(episodes, id: \.id) { episode in
                                    generateEpisodeItem(episode)
                                        .onAppear {
                                            if episodes.last == episode {
                                                // Check and see if there are more episodes to load.
                                            }
                                        }
                                }
                            }
                        } else {
                            ZStack {
                                RoundedRectangle(cornerRadius: 16)
                                    .episodeFrame()
                                    .foregroundColor(Color.gray.opacity(0.2))
                                
                                Label("Failed to load.", systemImage: "exclamationmark.triangle.fill")
                                    .font(.title3.bold())
                                    .foregroundColor(Color.red)
                            }
                        }
                    } header: {
                        buildSubHeading(title: "Episodes")
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.vertical, 6)
                            .background(Color.black)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal)
                }
            }
        }
    }
    
    @ViewBuilder
    private func generateEpisodeItem(
        _ episode: Episode
    ) -> some View {
        ZStack(alignment: .bottomLeading) {
            KFImage(episode.thumbnail.largest?.link)
                .cacheMemoryOnly()
                .placeholder {
                    Rectangle()
                        .foregroundColor(Color.gray.opacity(0.25))
                        .shimmering()
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
                    Text("E\(episode.number) \u{2022} \(episode.lengthFormatted)")
                        .font(.callout.bold())
                }
            }
            .padding()
        }
        .overlay(
            WithViewStore(
                store.scope(state: { $0.moreInfo.contains(episode.id) })
            ) { visibleViewStore in
                Button {
                    visibleViewStore.send(.moreInfo(id: episode.id), animation: Animation.easeInOut(duration: 0.15))
                } label: {
                    Image(
                        systemName: visibleViewStore.state ? "chevron.up" : "chevron.down"
                    )
                    .font(Font.system(size: 12, weight: .black))
                    .foregroundColor(Color.white.opacity(0.9))
                }
                .buttonStyle(BlurredButtonStyle())
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                .padding()
            }
        )

        WithViewStore(
            store.scope(state: { $0.moreInfo.contains(episode.id) })
        ) { visibleDescriptionViewStore in
            if visibleDescriptionViewStore.state {
                Text(episode.description)
                    .font(.footnote)
                    .padding(.horizontal)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.bottom)
            }
        }
    }
}

extension AnimeDetailView {
    @ViewBuilder
    func buildSubHeading(title: String) -> some View {
        Text(title)
            .font(.title.bold())
            .foregroundColor(.white)
    }
}

extension View {
    fileprivate func episodeFrame() -> some View {
        self
            .aspectRatio(16/9, contentMode: .fill)
            .cornerRadius(16)
            .frame(maxWidth: .infinity)
    }
}

extension AnimeDetailView {
    struct PlayButtonStyle: ButtonStyle {
        func makeBody(configuration: Configuration) -> some View {
            configuration.label
                .font(.system(size: 12).weight(.heavy))
                .padding()
                .background(Color.white)
                .foregroundColor(.black)
                .clipShape(Capsule())
                .scaleEffect(configuration.isPressed ? 0.9 : 1)
                .animation(.easeOut(duration: 0.2), value: configuration.isPressed)
        }
    }
}

struct AnimeView_Previews: PreviewProvider {
    @Namespace static var namespace

    static var previews: some View {
        AnimeDetailView(
            store: .init(
                initialState: .init(
                    anime: .narutoShippuden,
                    episodes: .success(.init(uniqueElements: Episode.demoEpisodes))
                ),
                reducer: AnimeDetailCore.reducer,
                environment: .init(
                    listClient: .mock
                )
            ),
            namespace: namespace
        )
        .preferredColorScheme(.dark)
    }
}
