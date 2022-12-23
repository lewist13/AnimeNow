//  SettingsExpandableListView.swift
//  Anime Now!
//
//  Created by ErrorErrorError on 11/27/22.
//  
//

import SwiftUI

struct SettingsRowExpandableListView<T: Equatable & Identifiable, I: View>: View {
    let items: [T]
    let rowView: () -> SettingsRowView<Text>
    var itemView: (T) -> I
    var selectedItem: ((T.ID) -> Void)? = nil

    @State private var expand = false

    var body: some View {
        LazyVStack(spacing: 0) {
            Spacer()

            rowView()
                .cornerRadius(0)
                .onTapped {
                    withAnimation {
                        expand.toggle()
                    }
                }

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
    static var previews: some View {
        SettingsRowExpandableListView(
            items: Episode.demoEpisodes
        ) {
            .init(name: "Episodes", text: "")
        } itemView: { episode in
            Text(episode.title)
        }
    }
}
