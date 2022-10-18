//
//  CompressableText.swift
//  Anime Now!
//
//  Created by ErrorErrorError on 9/14/22.
//

import SwiftUI

struct CompressableText: View {
    var array: [String] = []
    var max: Int = 3

    @State var seeMore = false

    var body: some View {
        VStack(alignment: .leading) {
            ForEach(array.indices, id: \.self) { index in
                let item = array[index]
                if index < max || seeMore {
                    Text(item)
                    if seeMore && index + 1 == array.count {
                        createText(title: "Read less", image: "chevron.up")
                    }
                } else if index == max {
                    createText(title: "Read more", image: "chevron.down")
                }
            }
        }
    }
}

extension CompressableText {
    @ViewBuilder
    func createText(title: String, image: String) -> some View {
        HStack(spacing: 6) {
            Text(title)
                .padding(0)
            Label("", systemImage: image)
                .labelStyle(.iconOnly)
        }
        .padding(0)
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.2)) {
                seeMore.toggle()
            }
        }
    }
}

struct CompressableText_Previews: PreviewProvider {
    static var previews: some View {
        CompressableText(
            array: ["this", "is", "a", "test"]
        )
    }
}
