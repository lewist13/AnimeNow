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
        VStack(alignment: .leading) {
            if !DeviceUtil.isMac {
                HStack {
                    Text("Your Collections")
                        .font(.largeTitle.bold())
                    Spacer()
                    Image(systemName: "plus")
                        .font(.title)
                }
                .padding()
            }

            WithViewStore(
                store,
                observe: { $0.collections.value ?? [] }
            ) { viewState in

                if viewState.count > 0 {
                    collections(viewState.state)
                } else {
                    showEmptyState
                }
            }
        }
    }
}

extension CollectionsView {
    @ViewBuilder
    func collections(
        _ collections: [CollectionStore]
    ) -> some View {
        ScrollView {
            LazyVGrid(
                columns: .init(
                    repeating: .init(
                        .flexible(),
                        spacing: 8
                    ),
                    count: DeviceUtil.isPhone ? 2 : 4
                )
            ) {
                ForEach(collections) { collection in
                    
                }
            }
        }
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
