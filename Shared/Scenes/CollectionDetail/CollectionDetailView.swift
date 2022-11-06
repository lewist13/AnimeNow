////  CollectionDetail.swift
//  Anime Now! (iOS)
//
//  Created by ErrorErrorError on 11/5/22.
//  
//

import SwiftUI
import ComposableArchitecture

struct CollectionDetail: View {
    let store: StoreOf<CollectionDetailReducer>

    var body: some View {
        Text(/*@START_MENU_TOKEN@*/"Hello, World!"/*@END_MENU_TOKEN@*/)
    }
}

struct CollectionDetail_Previews: PreviewProvider {
    static var previews: some View {
        CollectionDetail(
            store: .init(
                initialState: .init(),
                reducer: CollectionDetailReducer()
            )
        )
    }
}
