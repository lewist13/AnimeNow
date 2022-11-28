//
//  DownloadsView.swift
//  Anime Now!
//
//  Created by ErrorErrorError on 9/25/22.
//  Copyright © 2022. All rights reserved.
//

import ComposableArchitecture
import SwiftUI

struct DownloadsView: View {
    let store: StoreOf<DownloadsReducer>

    var body: some View {
        WithViewStore(store, observe: \.animes) { viewStore in
            if viewStore.count > 0 {
                ScrollView {
                    VStack {
                        ForEach(viewStore.state) {
                            FillAspectImage(url: $0.posterImage.first?.link)
                                .frame(maxWidth: .infinity)
                                .frame(height: 120)
                                .overlay(
                                    Text($0.title)
                                        .font(.title2.bold())
                                        .padding()
                                        .frame(
                                            maxWidth: .infinity,
                                            maxHeight: .infinity,
                                            alignment: .leading
                                        )
                                        .background(Color.black.opacity(0.35))
                                )
                        }
                    }
                }
            } else {
                VStack(spacing: 12) {
                    
                    Image(systemName: "square.and.arrow.down.fill")
                        .font(.largeTitle)
                        .foregroundColor(Color.gray)
                    
                    Text("Your downloads list is empty")
                        .foregroundColor(.white)
                    
                    Text("To download a show, click on the downloads icon on show details.")
                        .font(.callout)
                        .foregroundColor(.gray)
                }
                .multilineTextAlignment(.center)
                .padding()
            }
        }
        .frame(
            maxWidth: .infinity,
            maxHeight: .infinity
        )
        .onAppear {
            ViewStore(store).send(.onAppear)
        }
    }
}

struct DownloadsView_Previews: PreviewProvider {
    static var previews: some View {
        DownloadsView(
            store: .init(
                initialState: .init(),
                reducer: DownloadsReducer()
            )
        )
        .preferredColorScheme(.dark)
    }
}
