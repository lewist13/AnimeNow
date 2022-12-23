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

struct AttributedText: View {

    struct Options: Hashable {
        let fontSize: CGFloat
        var shadowColor: Color = .clear
        var shadowOffset: CGFloat = 0
        var strokeColor: Color = .clear
        var strokeWidth: CGFloat = 0
        var backgroundColor: Color = .clear
        var backgroundRadius: CGFloat = 0
        var backgroundPadding: CGFloat = 0
    }

    let text: String
    var options = Options.defaultBoxed

    var body: some View {
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
        AttributedText(text: "This is a subtitle test.", options: .defaultStroke)
            .padding(8)
            .background(Color.white)
    }
}
