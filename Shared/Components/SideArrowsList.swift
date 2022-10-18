//
//  SideArrowsList.swift
//  Anime Now!
//
//  Created by ErrorErrorError on 10/18/22.
//

import SwiftUI
import IdentifiedCollections

struct SideArrowsList<Content: View, T: Identifiable & Hashable>: View {

    let items: [T]
    let spacing: CGFloat
    var showArrows = false
    var content: (T) -> Content

    @State private var rangesVisible = Set<T.ID>()

    var body: some View {
        if showArrows {
            HStack {
                if showArrows, let first = items.first, !rangesVisible.contains(first.id) {
                    Image(systemName: "chevron.backward")
                        .padding()
                        .aspectRatio(9/16, contentMode: .fill)
                }

                createItems()

                if showArrows, let last = items.last, !rangesVisible.contains(last.id) {
                    Image(systemName: "chevron.forward")
                        .padding()
                        .aspectRatio(9/16, contentMode: .fill)
                }
            }
        } else {
            createItems()
        }
    }

    @ViewBuilder
    private func createItems() -> some View {
        let layout = [
            GridItem(.flexible())
        ]

        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHGrid(rows: layout, alignment: .center, spacing: spacing) {
                    ForEach(items) { item in
                        content(item)
                            .id(item.id)
                            .onAppear {
                                rangesVisible.insert(item.id)
                            }
                            .onDisappear {
                                rangesVisible.remove(item.id)
                            }
                    }
                }
                .padding(.horizontal)
            }
            .onChange(of: rangesVisible) { newValue in
                
            }
        }
    }
}
