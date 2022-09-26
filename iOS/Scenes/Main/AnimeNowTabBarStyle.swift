//
//  AnimeNowTabBarStyle.swift
//  Anime Now! (iOS)
//
//  Created by Erik Bautista on 9/25/22.
//

import SwiftUI

struct AnimeTabBarStyle: TabBarStyle {
    public func tabBar(with geometry: GeometryProxy, itemsContainer: @escaping () -> AnyView) -> some View {
        itemsContainer()
            .padding(.horizontal)
            .background(Color(hue: 0, saturation: 0, brightness: 0.03))
            .cornerRadius(geometry.size.height / 4)
            .fixedSize()
            .padding(.vertical, 32)
            .frame(maxWidth: .infinity)
    }
}

struct AnimeTabItemStyle: TabItemStyle {
    public func tabItem(item: TabBarRoute, isSelected: Bool) -> some View {
        Image(systemName: "\(isSelected ? item.selectedIcon : item.icon)")
            .font(.system(size: 20).weight(.semibold))
            .frame(width: 52, height: 52)
            .foregroundColor(isSelected ? Color.red : Color.white)
    }
}

