//  SettingsListView.swift
//  Anime Now!
//
//  Created by ErrorErrorError on 11/24/22.
//  
//

import SwiftUI

struct SettingsListView<I: Identifiable & CustomStringConvertible>: View {
    var items: [I]? = nil
    var selected: I.ID? = nil
    var selectedItem: ((I.ID) -> Void)? = nil

    var body: some View {
        if let items = items {
            VStack {
                ForEach(items, id: \.description) { item in
                    Text(item.description)
                        .font(.callout.bold())
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            selectedItem?(item.id)
                        }
                        .background(item.id == selected ? Color.primaryAccent : Color.clear)
                        .cornerRadius(12)
                }
            }
            .transition(
                .move(edge: .trailing)
                .combined(with: .opacity)
            )
            .frame(
                maxWidth: .infinity,
                maxHeight: .infinity
            )
        }
    }
}

struct SettingsListView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsListView(
            items: [Provider.gogoanime(id: "", dub: true)]
        )
    }
}
