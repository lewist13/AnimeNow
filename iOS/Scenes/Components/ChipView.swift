//
//  ChipView.swift
//  Anime Now! (iOS)
//
//  Created by Erik Bautista on 9/27/22.
//

import SwiftUI

struct ChipView: View {
    let text: String
    var symbol: String? = nil

    var body: some View {
        HStack {
            if let symbol = symbol {
                Image(systemName: symbol)
            }
            Text(text)
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
        .background(Color.gray.opacity(0.25))
        .clipShape(Capsule())
    }
}

struct ChipView_Previews: PreviewProvider {
    static var previews: some View {
        ChipView(
            text: "2021",
            symbol: nil
        )
        .preferredColorScheme(.dark)
    }
}
