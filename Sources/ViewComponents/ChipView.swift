//
//  ChipView.swift
//  Anime Now! (iOS)
//
//  Created by ErrorErrorError on 9/27/22.
//

import SwiftUI

public struct ChipView<Accessory: View>: View {
    let text: String
    var accessory: (() -> Accessory)?

    public init(
        text: String,
        accessory: (() -> Accessory)? = nil
    ) {
        self.text = text
        self.accessory = accessory
    }

    public var body: some View {
        HStack(
            alignment: .center,
            spacing: 8
        ) {
            accessory?()
            Text(text)
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
        .background(Capsule().foregroundColor(.gray).opacity(0.25))
        .clipShape(Capsule())
    }
}

extension ChipView where Accessory == EmptyView {
    public init(text: String) {
        self.init(text: text, accessory: nil)
    }
}

struct ChipView_Previews: PreviewProvider {
    static var previews: some View {
        ChipView(
            text: "2021",
            accessory: { Image(systemName: "star.fill") }
        )
        .preferredColorScheme(.dark)
    }
}
