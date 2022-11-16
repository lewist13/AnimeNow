//
//  CollectionsView.swift
//  Anime Now!
//
//  Created by ErrorErrorError on 10/15/22.
//  Copyright © 2022. All rights reserved.
//

import ComposableArchitecture
import SwiftUI

struct CollectionsView: View {
    let store: StoreOf<CollectionsReducer>

    var body: some View {
        WithViewStore(
            store,
            observe: \.selection
        ) { selectedViewState in
                ScrollView {
                    if !DeviceUtil.isMac {
                        HStack {
                            Spacer()

                            Text("My Collections")
                            Spacer()

                            Button {
                                
                            } label: {
                                Image(systemName: "plus")
                                    .foregroundColor(.white)
                            }
                        }
                        .font(.title3.bold())
                        .padding()
                    }

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
                .overlay(
                    Group {
                        switch selectedViewState.state {
                        case .some(.favorites):
                            EmptyView()
                        case let .some(.collection(id)):
                            IfLetStore(
                                store.scope(
                                    state: \.collections[id: id],
                                    action: { CollectionsReducer.Action.collectionDetail(id: id, action: $0) }
                                )
                            ) { collectionStore in
                                CollectionDetailView(
                                    store: collectionStore
                                )
                            }
                            .frame(
                                maxWidth: .infinity,
                                maxHeight: .infinity
                            )
                            .background(Color.black)
                            .transition(
                                DeviceUtil.isPhone ?
                                .move(edge: .trailing)
                                .combined(with: .opacity)
                                : .opacity
                            )
                        default:
                            EmptyView()
                        }
                    }
                )
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
            folderView(
                "Favorites",
                viewState.state
                    .prefix(3)
                    .compactMap(\.posterImage.largest?.link),
                viewState.state.count
            )
            .onTapGesture {
                viewState.send(
                    .setSelection(
                        selection: .favorites
                    ),
                    animation: .easeInOut
                )
            }
        }
    }
}

extension CollectionsView {
    @ViewBuilder
    var collections: some View {
        WithViewStore(
            store,
            observe: \.collections
        ) { viewState in
            ForEach(viewState.state) { collection in
                folderView(
                    collection.title.value,
                    collection.animes
                        .prefix(3)
                        .compactMap(\.posterImage.largest?.link),
                    collection.animes.count
                )
                .onTapGesture {
                    viewState.send(
                        .setSelection(
                            selection: .collection(
                                selected: collection.id
                            )
                        ),
                        animation: .easeInOut
                    )
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
