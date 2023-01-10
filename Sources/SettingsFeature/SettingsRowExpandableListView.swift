//  SettingsExpandableListView.swift
//  Anime Now!
//
//  Created by ErrorErrorError on 11/27/22.
//  
//

import SwiftUI

public struct SettingsRowExpandableListView<T: Equatable & Identifiable, I: View>: View {
    let items: [T]
    let rowView: () -> SettingsRowView<Text>
    var itemView: (T) -> I
    var selectedItem: ((T.ID) -> Void)? = nil

    @State private var expand = false

    public init(
        items: [T],
        rowView: @escaping () -> SettingsRowView<Text>,
        itemView: @escaping (T) -> I,
        selectedItem: ((T.ID) -> Void)? = nil
    ) {
        self.items = items
        self.rowView = rowView
        self.itemView = itemView
        self.selectedItem = selectedItem
    }

    public var body: some View {
        LazyVStack(spacing: 0) {
            Spacer()

            rowView()
                .cornerRadius(0)
                .onTapped {
                    withAnimation {
                        expand.toggle()
                    }
                }
                .disabled(items.count <= 1)

            if expand {
                ForEach(items, id: \.id) { item in
                    Color.gray.opacity(0.25)
                        .frame(maxWidth: .infinity)
                        .frame(height: 1)
                        .padding(.horizontal)

                    itemView(item)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal)
                        .padding(.vertical, 10)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            withAnimation {
                                expand = false
                                selectedItem?(item.id)
                            }
                        }
                }
            }
        }
        .background(Color(white: 0.2))
        .cornerRadius(12)
    }
}

struct SettingsExpandableListView_Previews: PreviewProvider {
    private struct SettingItem: Equatable, Identifiable {
        var id = 0
        var name: String = ""
    }

    static var previews: some View {
        SettingsRowExpandableListView(
            items: [SettingItem()]
        ) {
            .init(name: "Episodes", text: "")
        } itemView: { episode in
            Text(episode.name)
        }
    }
}
