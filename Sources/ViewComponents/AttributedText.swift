//  AttributedText.swift
//  Anime Now!
//
//  Created by ErrorErrorError on 12/7/22.
//

import SwiftUI

#if os(iOS)
fileprivate typealias TextView = UILabel
#else
fileprivate typealias TextView = NSTextField
#endif

public struct AttributedText: View {
    public struct Options: Hashable {
        let fontSize: CGFloat
        var shadowColor: Color
        var shadowOffset: CGFloat
        var strokeColor: Color
        var strokeWidth: CGFloat
        var backgroundColor: Color
        var backgroundRadius: CGFloat
        var backgroundPadding: CGFloat

        public init(
            fontSize: CGFloat,
            shadowColor: Color = .clear,
            shadowOffset: CGFloat = 0,
            strokeColor: Color = .clear,
            strokeWidth: CGFloat = 0,
            backgroundColor: Color = .clear,
            backgroundRadius: CGFloat = 0,
            backgroundPadding: CGFloat = 0
        ) {
            self.fontSize = fontSize
            self.shadowColor = shadowColor
            self.shadowOffset = shadowOffset
            self.strokeColor = strokeColor
            self.strokeWidth = strokeWidth
            self.backgroundColor = backgroundColor
            self.backgroundRadius = backgroundRadius
            self.backgroundPadding = backgroundPadding
        }
    }

    let text: String
    var options: Options

    public init(
        text: String,
        options: Options
    ) {
        self.text = text
        self.options = options
    }

    public var body: some View {
        TextViewRepresentable(
            text: text,
            options: options
        )
            .fixedSize()
            .padding(options.backgroundPadding)
            .background(
                options.backgroundColor
                    .cornerRadius(options.backgroundRadius)
            )
    }
}

private struct TextViewRepresentable: PlatformAgnosticViewRepresentable {
    var text: String
    var options: AttributedText.Options

    func makePlatformView(context: Context) -> TextView {
        let label = TextView(frame: .zero)
        label.lineBreakMode = .byWordWrapping

        #if os(iOS)
        label.numberOfLines = 0
        label.textAlignment = .center
        #else
        label.wantsLayer = true
        label.layer?.masksToBounds = false
        label.backgroundColor = .clear
        label.isBezeled = false
        label.isBordered = false
        label.isEditable = false
        label.sizeToFit()
        label.maximumNumberOfLines = 0
        label.alignment = .center
        #endif
        label.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        label.setContentHuggingPriority(.defaultHigh, for: .vertical)
        return label
    }

    func updatePlatformView(_ platformView: TextView, context: Context) {
        var attributedOptions: [NSAttributedString.Key : Any] = [:]

        if let strokeColorCG = options.strokeColor.cgColor {
            attributedOptions[.strokeColor] = strokeColorCG
            attributedOptions[.strokeWidth] = -abs(options.strokeWidth)
        }

        let attributedText = NSMutableAttributedString(
            string: text,
            attributes: attributedOptions
        )

        platformView.textColor = .white
        platformView.font = .init(name: "HelveticaNeue-Bold", size: options.fontSize)
//        platformView.font = .monospacedSystemFont(ofSize: options.fontSize, weight: .bold)

        #if os(iOS)
        platformView.attributedText = attributedText
        platformView.layer.shadowOffset = .init(width: options.shadowOffset, height: options.shadowOffset)
        platformView.layer.shadowColor = options.shadowColor.cgColor
        platformView.layer.shadowOpacity = 1.0
        platformView.layer.shadowRadius = 0
        #else
        platformView.attributedStringValue = attributedText
        platformView.layer?.shadowOffset = .init(width: options.shadowOffset, height: options.shadowOffset)
        platformView.layer?.shadowColor = options.shadowColor.cgColor
        platformView.layer?.shadowOpacity = 1.0
        platformView.layer?.shadowRadius = 0

        platformView.sizeToFit()
        #endif
    }
}

struct AttributedText_Preview: PreviewProvider {
    static var previews: some View {
        AttributedText(
            text: "This is a subtitle test.",
            options: .init(fontSize: 12)
        )
            .padding(8)
            .background(Color.white)
    }
}
