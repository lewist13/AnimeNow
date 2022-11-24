//
//  CollectionsView.swift
//  Anime Now!
//
//  Created by ErrorErrorError on 10/15/22.
//  Copyright © 2022. All rights reserved.
//

import SwiftUI
import ComposableArchitecture

struct CollectionsView: View {
    let store: StoreOf<CollectionsReducer>

    var body: some View {
        StackNavigation(title: "My Collections") {
            ScrollView {
                Spacer(minLength: 8)

                LazyVGrid(
                    columns: !DeviceUtil.isPhone ? [
                        .init(
                            .adaptive(minimum: 140),
                            spacing: 12
                        )
                    ] : .init(
                        repeating: .init(
                            .flexible(
                                maximum: 160
                            ),
                            spacing: 24
                        ),
                        count: 2
                    ),
                    spacing: 24
                ) {
                    favorites
                    collections
                }
                .padding()

                ExtraBottomSafeAreaInset()
            }
        } buttons: {
            Button {
                ViewStore(store).send(.onAddNewCollectionTapped)
            } label: {
                Image(systemName: "plus")
                    .foregroundColor(.white)
                    .font(.title2.bold())
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
        .onAppear {
            ViewStore(store).send(.onAppear)
        }
        .frame(
            maxWidth: .infinity,
            maxHeight: .infinity
        )
    }
}

extension CollectionsView {
    @ViewBuilder
    var favorites: some View {
        WithViewStore(
            store,
            observe: \.favorites
        ) { viewState in
            StackNavigationLink(
                id: "favorites-id",
                title: "Favorites"
            ) {
                AnyView(
                    folderView(
                        "Favorites",
                        viewState.state
                            .prefix(3)
                            .compactMap(\.posterImage.largest?.link),
                        viewState.state.count
                    )
                )
            } destination: {
                AnyView(
                    collectionsPage(title: "Favorites", viewState.state)
                )
            }
        }
    }
}

extension CollectionsView {
    @ViewBuilder
    func collectionsPage(
        title: String,
        _ animes: [AnimeStore],
        collectionId: CollectionStore.ID? = nil
    ) -> some View {
        ScrollView {
            LazyVGrid(
                columns: .init(
                    repeating: .init(
                        .flexible(),
                        spacing: 16
                    ),
                    count: DeviceUtil.isPhone ? 2 : 6
                )
            ) {
                ForEach(animes) { anime in
                    AnimeItemView(
                        anime: anime
                    )
                    .onTapGesture {
                        ViewStore(store).send(.onAnimeTapped(anime))
                    }
                    .contextMenu {
                        Button {
                            if let collectionId {
                                ViewStore(store).send(.removeAnimeFromCollection(collectionId, anime))
                            } else {
                                ViewStore(store).send(.removeAnimeFromFavorites(anime))
                            }
                        } label: {
                            Text("Remove from \(collectionId != nil ? "Collections" : "Favorites")")
                        }
                    }
                }
            }
            .padding([.top, .horizontal])
            
            ExtraBottomSafeAreaInset()
            Spacer(minLength: 32)
        }
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
    }
}

extension CollectionsView {
    @ViewBuilder
    var collections: some View {
        WithViewStore(
            store,
            observe: \.collections
        ) { collections in
            ForEach(collections.state) { collection in
                StackNavigationLink(
                    id: collection.id,
                    title: collection.title.value
                ) {
                        folderView(
                            collection.title.value,
                            collection.animes
                                .prefix(3)
                                .compactMap(\.posterImage.largest?.link),
                            collection.animes.count
                        )
                } destination: {
                        collectionsPage(
                            title: collection.title.value,
                            Array(collection.animes),
                            collectionId: collection.id
                        )
                            .id(collection.title)
                }
                .contextMenu {
                    if collection.title.canDelete {
                        Button {
                            ViewStore(store).send(.deleteCollection(id: collection.id))
                        } label: {
                            Label(
                                "Delete Collection",
                                systemImage: "trash.fill"
                            )
                        }
                        .foregroundColor(Color.red)
                    }
                }
            }
        }
    }
}

extension CollectionsView {
    @ViewBuilder
    func folderView(
        _ title: String = "",
        _ images: [URL?] = [],
        _ count: Int = 0
    ) -> some View {
        VStack(alignment: .leading) {
            ZStack(alignment: .bottom) {
                let cornerRadius: CGFloat = 12
                let padding: CGFloat = 12
                let aspectRatio: CGFloat = 5/7
                let offsetBy: CGFloat = 28
                if images.count == 0 {
                    Color(
                        white: 0.1
                    )
                    .overlay(
                        Image(
                            "rectangle.portrait.slash"
                        )
                        .font(.largeTitle)
                        .foregroundColor(.white)
                    )
                    .aspectRatio(aspectRatio, contentMode: .fit)
                    .cornerRadius(cornerRadius)
                } else {
                    ForEach(
                        Array(zip(images.indices, images)),
                        id: \.0
                    ) { (index, url) in
                        FillAspectImage(
                            url: url
                        )
                        .aspectRatio(aspectRatio, contentMode: .fit)
                        .zIndex(.init(images.count - index))
                        .cornerRadius(cornerRadius / CGFloat(index + 1))
                        .padding(CGFloat(index) * padding)
                        .offset(y: -CGFloat(index) * offsetBy)
                    }
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .lineLimit(1)
                    .font(.headline.bold())
                    .foregroundColor(.white)

                Text("\(count) ITEMS")
                    .font(.caption.bold())
                    .foregroundColor(.gray)
            }
        }
        .frame(
            maxWidth: .infinity,
            maxHeight: .infinity
        )
    }
}

extension CollectionsView {
    @ViewBuilder
    func collectionView(
        _ title: String,
        _ animes: [AnimeStore]
    ) -> some View {
        EmptyView()
    }
}

extension CollectionsView {
    @ViewBuilder
    var showEmptyState: some View {
        VStack(spacing: 12) {
            Image("rectangle.stack.badge.play")
                .font(.largeTitle)
                .foregroundColor(Color.gray)

            Text("Your collection is empty")
                .foregroundColor(.white)

            Text("To add to your collection, click on the plus icon on the show details.")
                .font(.callout)
                .foregroundColor(.gray)
        }
        .multilineTextAlignment(.center)
        .padding()
        .frame(
            maxWidth: .infinity,
            maxHeight: .infinity
        )
    }
}

struct LibraryView_Previews: PreviewProvider {
    static var previews: some View {
        CollectionsView(
            store: .init(
                initialState: .init(),
                reducer: CollectionsReducer()
            )
        )
        .preferredColorScheme(.dark)
    }
}
