////  CollectionDetail.swift
//  Anime Now! (iOS)
//
//  Created by ErrorErrorError on 11/5/22.
//  
//

import SwiftUI
import ComposableArchitecture

struct CollectionDetailView: View {
    let store: StoreOf<CollectionDetailReducer>

    var body: some View {
        VStack {
            WithViewStore(
                store,
                observe: \.title
            ) { titleViewStore in
                HStack {
                    Button {
                        titleViewStore.send(.close)
                    } label: {
                        Image(systemName: "chevron.backward")
                            .padding(8)
                    }
                    .buttonStyle(.plain)
                    .foregroundColor(.white)

                    Text(titleViewStore.value)
                    Spacer()
                }
                .font(.title3.bold())
                .padding(.horizontal)
            }

            ScrollView {
//                WithViewStore(
//                    store,
//                    observe: \.animes
//                ) { animes in
//                    LazyVGrid(
//                        columns: .init(
//                            repeating: .init(
//                                .flexible(),
//                                spacing: 16
//                            ),
//                            count: DeviceUtil.isPhone ? 2 : 6
//                        )
//                    ) {
//                        ForEach(
//                            animes.state,
//                            id: \.id
//                        ) { anime in
//                            AnimeItemView(anime: anime)
//                                .onTapGesture {
//                                    animes.send(.onAnimeTapped(anime))
//                                }
//                        }
//                    }
//                    .padding([.top, .horizontal])
//                }

                ExtraBottomSafeAreaInset()
                Spacer(minLength: 32)
            }
        }
    }
}

struct CollectionDetail_Previews: PreviewProvider {
    static var previews: some View {
        CollectionDetailView(
            store: .init(
                initialState: .init(title: .custom("Demo")),
                reducer: CollectionDetailReducer()
            )
        )
    }
}
