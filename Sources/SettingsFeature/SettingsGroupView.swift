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
        LazyVStack(alignment: .leading, spacing: 0) {
            label()
            LazyVStack(spacing: 1) {
                items()
            }
            .background(Color(white: 0.3))
            .cornerRadius(padding)
        }
    }
}

public struct GroupLabel: View {
    let title: String
    let padding = 12.0

    public var body: some View {
        Text(title)
            .font(.system(size: 13, weight: .semibold))
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
            SettingsRowView(
                name: "No",
                text: "haha"
            )
        }
        .previewLayout(.sizeThatFits)
        .padding()
        .background(Color(white: 0.1))
    }
}
