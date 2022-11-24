//
//  AppView.swift
//  Anime Now! (macOS)
//
//  Created by ErrorErrorError on 9/3/22.
//

import SwiftUI
import ComposableArchitecture

extension AppView {

    @ViewBuilder
    var tabBar: some View {
        WithViewStore(
            store,
            observe: { $0.route }
        ) { selected in
            HStack(spacing: 32) {
                Text("Anime Now!")
                    .font(.largeTitle.bold())
                    .foregroundColor(.white)

                HStack(spacing: 8) {
                    ForEach(
                        AppReducer.Route.allCases,
                        id: \.self
                    ) { route in
                        Text(route.title)
                            .font(.headline)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 10)
                            .foregroundColor(selected.state == route ? Color.white : Color.gray)
                            .clipShape(Capsule())
                            .contentShape(Rectangle())
                            .onTapGesture {
                                selected.send(
                                    .set(\.$route, route),
                                    animation: .linear(duration: 0.15)
                                )
                            }
                    }
                }
            }
            .padding()
            .frame(
                maxWidth: .infinity,
                alignment: .leading
            )
            .background(
                LinearGradient(
                    stops: [
                        .init(
                            color: .black.opacity(0.75),
                            location: 0.0
                        ),
                        .init(
                            color: .clear,
                            location: 1.0
                        ),
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea(.container, edges: .top)
            )
        }
    }
}

struct AppView_macOS_Previews: PreviewProvider {
    static var previews: some View {
        AppView(
            store: .init(
                initialState: .init(),
                reducer: AppReducer()
            )
        )
    }
}
