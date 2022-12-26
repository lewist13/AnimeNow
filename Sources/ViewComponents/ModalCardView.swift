//  ModalCardView.swift
//  Anime Now!
//
//  Created by ErrorErrorError on 11/18/22.
//
// Modified version from https://github.com/joogps/SlideOverCard

import SwiftUI
import Utilities

public struct ModalCardView<Content: View, ShapeType: ShapeStyle>: View {
    let onDismiss: (() -> Void)?
    var options: Set<ModalCardOptions>
    let style: ModalCardStyle<ShapeType>
    let content: Content

    @GestureState private var viewOffset: CGFloat = 0.0

    var isiPad: Bool {
        DeviceUtil.isPad || DeviceUtil.isMac
    }

    public init(
        onDismiss: (() -> Void)? = nil,
        options: Set<ModalCardOptions> = [],
        style: ModalCardStyle<ShapeType> = .init(),
        content: @escaping () -> Content
    ) {
        self.onDismiss = onDismiss
        self.options = options
        self.style = style
        self.content = content()
    }

    public var body: some View {
        ZStack {
            Color.black.opacity(0.5)
                .blur(radius: 12)
                .edgesIgnoringSafeArea(.all)
                .transition(.opacity)
                .zIndex(1)

            Group {
                if #available(iOS 14.0, *) {
                    container
                        .ignoresSafeArea(.container, edges: .bottom)
                } else {
                    container
                        .edgesIgnoringSafeArea(.bottom)
                }
            }
            .zIndex(2)
            .transition(isiPad ? .opacity.combined(with: .offset(x: 0, y: 200)) : .move(edge: .bottom))
        }
        .animation(.spring(response: 0.35, dampingFraction: 1), value: viewOffset)
    }

    private var container: some View {
        VStack {
            Spacer()
            if isiPad {
                card
                    .aspectRatio(1.0, contentMode: .fit)
                    .fixedSize()
                Spacer()
            } else {
                card
            }
        }
    }

    private var cardShape: some Shape {
        RoundedRectangle(
            cornerSize: style.cornerSize,
            style: .continuous
        )
    }

    private var card: some View {
        VStack(alignment: .trailing, spacing: 0) {
            if !options.contains(.hideDismissButton) {
                Button(action: dismiss) {
                    ZStack {
                        Circle()
                            .fill(Color(white: 0.19))
                        Image(systemName: "xmark")
                            .resizable()
                            .scaledToFit()
                            .font(Font.body.weight(.bold))
                            .scaleEffect(0.416)
                            .foregroundColor(Color(white: 0.62))
                    }
                }
                .buttonStyle(.plain)
                .frame(width: 24, height: 24)
            }

            HStack {
                Spacer()
                content
                    .padding([.horizontal, options.contains(.hideDismissButton) ? .vertical : .bottom], 14)
                Spacer()
            }
        }
        .padding(style.innerPadding)
        .background(cardShape.fill(style.style))
        .clipShape(cardShape)
        .offset(x: 0, y: viewOffset/pow(2, abs(viewOffset)/500+1))
        .padding(style.outerPadding)
        .gesture(
            options.contains(.disableDrag) ? nil :
                DragGesture()
                .updating($viewOffset) { value, state, transaction in
                    state = value.translation.height
                }
                .onEnded() { value in
                    if value.predictedEndTranslation.height > 175 && !options.contains(.disableDragToDismiss) {
                        dismiss()
                    }
                }
        )
    }

    func dismiss() {
        if let onDismiss {
            onDismiss()
        }
    }
}

extension ModalCardView where ShapeType == Color {
    init(
        onDismiss: (() -> Void)? = nil,
        options: Set<ModalCardOptions> = [],
        content: @escaping () -> Content
    ) {
        self.onDismiss = onDismiss
        self.options = options
        self.style = .init()
        self.content = content()
    }
}

/// A struct thtat defines the style of a `SlideOverCard`

public struct ModalCardStyle<S: ShapeStyle> {
    /// Initialize a style with a single value for corner radius
    public init(
        corners: CGFloat = 38.5,
        continuous: Bool = true,
        innerPadding: CGFloat = 20.0,
        outerPadding: CGFloat = 6.0,
        style: S = Color(white: 0.12, opacity: 1.0)
    ) {
        self.init(
            corners: CGSize(width: corners, height: corners),
            continuous: continuous,
            innerPadding: innerPadding,
            outerPadding: outerPadding,
            style: style
        )
    }
        
    /// Initialize a style with a custom corner size
    public init(
        corners: CGSize,
        continuous: Bool = true,
        innerPadding: CGFloat = 20.0,
        outerPadding: CGFloat = 6.0,
        style: S = Color(white: 0.12, opacity: 1.0)
    ) {
        self.cornerSize = corners
        self.continuous = continuous
        self.innerPadding = innerPadding
        self.outerPadding = outerPadding
        self.style = style
    }
        
    let cornerSize: CGSize
    let continuous: Bool
        
    let innerPadding: CGFloat
    let outerPadding: CGFloat
        
    let style: S
}

/// A structure that defines interaction options of a `SlideOverCard`

public enum ModalCardOptions: CaseIterable {
    case disableDrag
    case disableDragToDismiss
    case hideDismissButton
}

extension View {
    public func slideOverCard<Content: View, ShapeType: ShapeStyle>(
        onDismiss: (() -> Void)? = nil,
        options: Set<ModalCardOptions> = [],
        style: ModalCardStyle<ShapeType> = .init(),
        @ViewBuilder content: @escaping () -> Content
    ) -> some View {
        return ZStack {
            self
            ModalCardView(
                onDismiss: onDismiss,
                options: options,
                style: style
            ) {
                content()
            }
        }
    }
}

struct ModalCardView_Previews: PreviewProvider {
    static var previews: some View {
        ModalCardView() {
            VStack(alignment: .center, spacing: 25) {
                VStack {
                    Text("Large title").font(.system(size: 28, weight: .bold))
                    Text("A nice and brief description")
                }

                ZStack {
                    RoundedRectangle(cornerRadius: 25.0, style: .continuous).fill(Color.gray)
                    Text("Content").foregroundColor(.white)
                }

                VStack(spacing: 0) {
                    Button {
                        
                    } label: {
                        HStack {
                            Spacer()
                            Text("What the fuck")
                                .padding(.vertical, 20)
                            Spacer()
                        }
                    }
                    .background(Color.white)
                    .cornerRadius(12)

                    Button {
                        
                    } label: {
                        HStack {
                            Spacer()
                            Text("Skip pls")
                                .padding(.vertical, 20)
                            Spacer()
                        }
                    }

                    .cornerRadius(12)
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}
