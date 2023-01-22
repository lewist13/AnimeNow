//
//  SettingsGroupView.swift
//  
//
//  Created by ErrorErrorError on 1/12/23.
//  
//

import SwiftUI

public struct SettingsGroupView<Label: View, Items: View>: View {
    let label: () -> Label
    let items: () -> Items

    private var padding = 12.0

    public init(
        @ViewBuilder label: @escaping () -> Label,
        @ViewBuilder items: @escaping () -> Items
    ) {
        self.label = label
        self.items = items
    }

    public var body: some View {
        LazyVStack(
            alignment: .leading,
            spacing: 0
        ) {
            label()
            divider
            LazyVStack(spacing: 1) {
                items()
            }
        }
        .background(Color(white: 0.2))
        .cornerRadius(padding)
    }

    @ViewBuilder
    private var divider: some View {
        Rectangle()
            .frame(height: 1)
            .foregroundColor(.gray.opacity(0.15))
            .fixedSize(horizontal: false, vertical: true)
            .padding(.horizontal, padding)
    }
}

public struct GroupLabel: View {
    let title: String
    let padding = 12.0

    public var body: some View {
        Text(title)
            .font(.headline.bold())
            .foregroundColor(.white)
            .padding(padding)
            .padding(.vertical, 4)
    }
}

extension SettingsGroupView {
    public init(
        title: String,
        @ViewBuilder items: @escaping () -> Items
    ) where Label == GroupLabel {
        self.init(
            label: { GroupLabel(title: title) },
            items: items
        )
    }

    public init(@ViewBuilder items: @escaping () -> Items) where Label == EmptyView {
        self.init(
            label: { EmptyView() },
            items: items
        )
    }
}

struct SettingsGroupView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsGroupView(title: "Group 1") {
            SettingsRowView(name: "Yes")
                .cornerRadius(0)
            SettingsRowView(
                name: "No",
                text: "haha"
            )
                .cornerRadius(0)
        }
        .previewLayout(.sizeThatFits)
        .padding()
        .background(Color(white: 0.1))
    }
}
