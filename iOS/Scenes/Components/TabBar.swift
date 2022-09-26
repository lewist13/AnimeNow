//  From https://github.com/onl1ner/TabBar
//
//  MIT License
//
//  Copyright (c) 2021 Tamerlan Satualdypov
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.

import SwiftUI

public enum TabBarRoute: String {
    case home
    case search
    case downloads

    var icon: String {
        switch self {
        case .home:
            return "house"
        case .search:
            return "magnifyingglass"
        case .downloads:
            return "arrow.down"
        }
    }

    var selectedIcon: String {
        switch self {
        case .home:
            return "house.fill"
        case .search:
            return self.icon
        case .downloads:
            return self.icon
        }
    }

    var title: String {
        self.rawValue
    }
}

public struct TabBar<Content: View>: View {

    private let selectedItem: TabBarSelection
    private let content: Content

    private var tabItemStyle : AnyTabItemStyle
    private var tabBarStyle  : AnyTabBarStyle
    
    @State private var items: [TabBarRoute]
    
    @Binding private var visibility: TabBarVisibility
    
    public init(
        selection: Binding<TabBarRoute>,
        visibility: Binding<TabBarVisibility> = .constant(.visible),
        @ViewBuilder content: () -> Content
    ) {
        self.tabItemStyle = .init(itemStyle: DefaultTabItemStyle())
        self.tabBarStyle = .init(barStyle: DefaultTabBarStyle())

        self.selectedItem = .init(selection: selection)
        self.content = content()

        self._items = .init(initialValue: .init())
        self._visibility = visibility
    }
    
    private var tabItems: some View {
        HStack {
            ForEach(self.items, id: \.self) { item in
                self.tabItemStyle.tabItem(item: item, isSelected: self.selectedItem.selection == item)
                    .onTapGesture { [item] in
                        self.selectedItem.selection = item
                        self.selectedItem.objectWillChange.send()
                    }
            }
            .frame(maxWidth: .infinity)
        }
    }
    
    public var body: some View {
        ZStack {
            self.content
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .environmentObject(self.selectedItem)
            
            GeometryReader { geometry in
                VStack {
                    Spacer()
                    
                    self.tabBarStyle.tabBar(with: geometry) {
                        .init(self.tabItems)
                    }
                }
                .edgesIgnoringSafeArea(.bottom)
                .visibility(self.visibility)
            }
        }
        .onPreferenceChange(TabBarPreferenceKey.self) { value in
            self.items = value
        }
    }
    
}

extension TabBar {
    public func tabItem<ItemStyle: TabItemStyle>(style: ItemStyle) -> Self {
        var _self = self
        _self.tabItemStyle = .init(itemStyle: style)
        return _self
    }
    
    public func tabBar<BarStyle: TabBarStyle>(style: BarStyle) -> Self {
        var _self = self
        _self.tabBarStyle = .init(barStyle: style)
        return _self
    }
}

public enum TabBarVisibility: CaseIterable {
    case visible
    case invisible
    
    public mutating func toggle() {
        switch self {
        case .visible:
            self = .invisible
        case .invisible:
            self = .visible
        }
    }
}

struct TabBarViewModifier: ViewModifier {
    @EnvironmentObject private var selectionObject: TabBarSelection

    let item: TabBarRoute

    func body(content: Content) -> some View {
        Group {
            if self.item == self.selectionObject.selection {
                content
            } else {
                Color.clear
            }
        }
        .preference(key: TabBarPreferenceKey.self, value: [self.item])
    }
}

extension View {
    public func tabItem(for item: TabBarRoute) -> some View {
        return self.modifier(TabBarViewModifier(item: item))
    }

    @ViewBuilder
    public func visibility(_ visibility: TabBarVisibility) -> some View {
        switch visibility {
        case .visible:
            self.transition(.move(edge: .bottom))
        case .invisible:
            hidden().transition(.move(edge: .bottom))
        }
    }
}

class TabBarSelection: ObservableObject {
    @Binding var selection: TabBarRoute

    init(selection: Binding<TabBarRoute>) {
        self._selection = selection
    }
}

struct TabBarPreferenceKey: PreferenceKey {
    static var defaultValue: [TabBarRoute] {
        return .init()
    }
    
    static func reduce(value: inout [TabBarRoute], nextValue: () -> [TabBarRoute]) {
        value.append(contentsOf: nextValue())
    }
}

public protocol TabBarStyle {
    associatedtype Content: View
    
    func tabBar(with geometry: GeometryProxy, itemsContainer: @escaping () -> AnyView) -> Content
}

extension TabBarStyle {
    func tabBarErased(with geometry: GeometryProxy, itemsContainer: @escaping () -> AnyView) -> AnyView {
        return .init(self.tabBar(with: geometry, itemsContainer: itemsContainer))
    }
}

public struct DefaultTabBarStyle: TabBarStyle {
    
    public func tabBar(with geometry: GeometryProxy, itemsContainer: @escaping () -> AnyView) -> some View {
        VStack(spacing: 0.0) {
            Divider()
            
            VStack {
                itemsContainer()
                    .frame(height: 50.0)
                    .padding(.bottom, geometry.safeAreaInsets.bottom)
            }
            .background(
                Color(
                    red:   249 / 255,
                    green: 249 / 255,
                    blue:  249 / 255,
                    opacity: 0.94
                )
            )
            .frame(height: 50.0 + geometry.safeAreaInsets.bottom)
        }
    }
    
}

public struct AnyTabBarStyle: TabBarStyle {
    private let _makeTabBar: (GeometryProxy, @escaping () -> AnyView) -> AnyView
    
    public init<BarStyle: TabBarStyle>(barStyle: BarStyle) {
        self._makeTabBar = barStyle.tabBarErased
    }
    
    public func tabBar(with geometry: GeometryProxy, itemsContainer: @escaping () -> AnyView) -> some View {
        return self._makeTabBar(geometry, itemsContainer)
    }
}

public protocol TabItemStyle {
    associatedtype Content : View

    func tabItem(item: TabBarRoute, isSelected: Bool) -> Content
}

extension TabItemStyle {
    func tabItemErased(item: TabBarRoute, isSelected: Bool) -> AnyView {
        return .init(self.tabItem(item: item, isSelected: isSelected))
    }
}

public struct DefaultTabItemStyle: TabItemStyle {

    @ViewBuilder
    public func tabItem(item: TabBarRoute, isSelected: Bool) -> some View {
        let color: Color = isSelected ? .accentColor : .gray
        
        VStack(spacing: 5.0) {
            Image(systemName: item.icon)
                .renderingMode(.template)

            Text(item.title)
                .font(.system(size: 10.0, weight: .medium))
        }
        .foregroundColor(color)
    }
    
}

public struct AnyTabItemStyle: TabItemStyle {
    private let _makeTabItem: (TabBarRoute, Bool) -> AnyView

    public init<TabItem: TabItemStyle>(itemStyle: TabItem) {
        self._makeTabItem = itemStyle.tabItemErased(item:isSelected:)
    }
    
    public func tabItem(item: TabBarRoute, isSelected: Bool) -> some View {
        return self._makeTabItem(item, isSelected)
    }
}
