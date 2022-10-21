//
//  CollectionView.swift
//  Anime Now!
//
//  Created by ErrorErrorError on 10/15/22.
//  Copyright © 2022. All rights reserved.
//

import ComposableArchitecture
import SwiftUI

struct CollectionView: View {
    let store: StoreOf<CollectionCore>

    var body: some View {
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
        CollectionView(
            store: .init(
                initialState: .init(),
                reducer: CollectionCore()
            )
        )
        .preferredColorScheme(.dark)
    }
}
