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

    @State var expandSummary = false

    struct ViewState: Equatable {
        let animeStatus: Anime.Status
        let animeFormat: Anime.Format

        init(_ state: AnimeDetailCore.State) {
            self.animeStatus = state.anime.status
            self.animeFormat = state.anime.format
        }
    }

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 0) {
                topContainer
                infoContainer

                WithViewStore(
                    store.scope(state: ViewState.init)
                ) { viewState in
                    if viewState.state.animeStatus != .upcoming &&
                        viewState.state.animeFormat == .tv {
                        episodesContainer
                    }
                }
            }
        }
        .transition(.move(edge: .bottom).combined(with: .opacity))
        .frame(maxWidth: .infinity)
        .statusBar(hidden: true)
        .ignoresSafeArea(edges: .top)
        .overlay(closeButton)
        .background(
            Color.black
                .ignoresSafeArea()
        )
        .onAppear {
            ViewStore(store.stateless).send(.onAppear)
        }
    }
}

// Close button

extension AnimeDetailView {
    @ViewBuilder var closeButton: some View {
        Button {
            ViewStore(store.stateless)
                .send(.closeButtonPressed)
        } label: {
            Image(
                systemName: "xmark"
            )
            .font(Font.system(size: 14, weight: .black))
            .foregroundColor(Color.white.opacity(0.9))
        }
        .buttonStyle(BlurredButtonStyle())
        .clipShape(Circle())
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
        .padding()
        .edgesIgnoringSafeArea(.top)
    }
}

// MARK: - Top Container

extension AnimeDetailView {

    @ViewBuilder
    var topContainer: some View {
        WithViewStore(
            store.scope(
                state: \.anime
            )
        ) { viewStore in
            ZStack(alignment: .bottom) {
                KFImage(viewStore.posterImage.largest?.link)
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

                VStack(alignment: .leading, spacing: 0) {
                    Text(viewStore.title)
                        .font(.largeTitle)
                        .bold()
                        .multilineTextAlignment(.leading)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity, alignment: .leading)

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
            }
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
            VStack(alignment: .leading) {
                HStack(alignment: .center, spacing: 12) {
                    buildSubHeading(title: "Summary")
                    Image(systemName: expandSummary ? "chevron.up" : "chevron.down")
                        .font(Font.system(size: 18, weight: .black))
                        .foregroundColor(Color.white.opacity(0.9))
                    Spacer()
                }
                .padding(.vertical, 6)
                .onTapGesture {
                    withAnimation(.easeInOut(duration: 0.15)) {
                        expandSummary.toggle()
                    }
                }

                LazyVStack {
                    Text(anime.description)
                        .font(.body)
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

                if anime.state.studios.count > 0 {
                    VStack(alignment: .leading) {
                        Text("Studios")
                            .bold()
                            .foregroundColor(Color.gray)
                        CompressableText(
                            array: anime.state.studios,
                            max: 3
                        )
                    }
                    .font(.callout)
                    .padding(.vertical)
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
            store.scope(state: \.episodes)
        ) { episodesViewStore in
            VStack {
                buildSubHeading(title: "Episodes")
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 6)
                    .background(Color.black)

                if episodesViewStore.state.isLoading == true {
                    episodeShimmeringView
                } else if case let .success(episodes) = episodesViewStore.state {
                    LazyVStack {
                        ForEach(episodes, id: \.id) { episode in
                            generateEpisodeItem(episode)
                                .onTapGesture {
                                    episodesViewStore.send(
                                        .selectedEpisode(
                                            episode: episode
                                        )
                                    )
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
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal)
    }

    @ViewBuilder
    private func generateEpisodeItem(
        _ episode: Episode
    ) -> some View {
        EpisodeItemBigView(episode: episode)
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
                    .clipShape(Circle())
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

    @ViewBuilder
    private var episodeShimmeringView: some View {
        RoundedRectangle(cornerRadius: 16)
            .episodeFrame()
            .foregroundColor(Color.gray.opacity(0.2))
            .shimmering()
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
            .frame(maxWidth: .infinity, alignment: .center)
            .cornerRadius(16)
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
    static var previews: some View {
        AnimeDetailView(
            store: .init(
                initialState: .init(
                    anime: .narutoShippuden,
                    episodes: .success(.init(uniqueElements: Episode.demoEpisodes))
                ),
                reducer: .empty,
                environment: ()
            )
        )
        .preferredColorScheme(.dark)
    }
}
