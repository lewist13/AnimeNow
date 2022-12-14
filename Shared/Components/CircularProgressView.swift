//
//  CircularProgressView.swift
//  Anime Now!
//
//  Created by ErrorErrorError on 11/28/22.
//  


import SwiftUI

struct CircularProgressView: View {
    var progress: CGFloat = 0.5

    var body: some View {
        GeometryReader { reader in
            ZStack {
                ArcShape(progress: 1.0)
                    .stroke(style: StrokeStyle(lineWidth: 3, lineCap: .round))
                    .opacity(0.3)

                ArcShape(progress: progress)
                    .stroke(style: StrokeStyle(lineWidth: 3, lineCap: .round))

                Rectangle()
                    .frame(width: reader.size.width / 1.5)
                    .frame(height: reader.size.width / 1.5)
            }
        }
        .animation(.linear, value: progress)
        .fixedSize()
    }
}

private struct ArcShape: Shape {
    let progress: CGFloat

    func path(in rect: CGRect) -> Path {
        var p = Path()

        p.addArc(
            center: CGPoint(x: rect.width / 2.0, y: rect.height / 2.0),
            radius: rect.height / 2.0 + 5.0,
            startAngle: .degrees(-90.0),
            endAngle: .degrees(360.0 * Double(progress) - 90.0),
            clockwise: false
        )

        return p
    }
}

struct CircularProgressView_Previews: PreviewProvider {
    static var previews: some View {
        CircularProgressView()
            .previewLayout(.sizeThatFits)
    }
}
