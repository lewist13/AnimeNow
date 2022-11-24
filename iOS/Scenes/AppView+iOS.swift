//
//  AppView.swift
//  Shared
//
//  Created by ErrorErrorError on 9/2/22.
//

import SwiftUI
import ComposableArchitecture

extension AppView {
    @ViewBuilder
    var tabBar: some View {
        WithViewStore(
            store,
            observe: \.route
        ) { viewStore in
            HStack(spacing: 0) {
                ForEach(
                    AppReducer.Route.allCases,
                    id: \.self
                ) { item in
                    Group {
                        if item.isIconSystemImage {
                            Image(
                                systemName: "\(item == viewStore.state ? item.selectedIcon : item.icon)"
                            )
                        } else {
                            Image("\(item == viewStore.state ? item.selectedIcon : item.icon)")
                        }
                    }
                    .foregroundColor(
                        item == viewStore.state ? Color.white : Color.gray
                    )
                    .font(.system(size: 20).weight(.semibold))
                    .frame(
                        width: 56,
                        height: 56,
                        alignment: .center
                    )
                    .onTapGesture {
                        viewStore.send(
                            .set(\.$route, item),
                            animation: .linear(duration: 0.15)
                        )
                    }
                }
            }
            .padding(.horizontal, 12)
            .background(Color(white: 0.08))
            .clipShape(Capsule())
            .padding(.bottom, DeviceUtil.hasBottomIndicator ? 0 : 24)
        }
    }
}
