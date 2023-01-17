//  ModalCardContainer.swift
//  Anime Now!
//
//  Created by ErrorErrorError on 11/18/22.
//
// Modified version from https://github.com/joogps/SlideOverCard

import SwiftUI
import Utilities

public struct ModalCardContainer<Content: View>: View {
    private let corners: CGFloat = 38.5
    private let continuous: Bool = true
    private let innerPadding: CGFloat = 20.0
    private let outerPadding: CGFloat = 6.0
    private let style = Color(white: 0.12, opacity: 1.0)

    let onDismiss: (() -> Void)?
    let content: () -> Content

    @GestureState private var viewOffset: CGFloat = 0.0

    var isLargeDisplay: Bool {
        DeviceUtil.isPad || DeviceUtil.isMac
    }

    public init(
        onDismiss: (() -> Void)? = nil,
        content: @escaping () -> Content
    ) {
        self.onDismiss = onDismiss
        self.content = content
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
            .transition(isLargeDisplay ? .opacity.combined(with: .offset(x: 0, y: 200)) : .move(edge: .bottom))
        }
        .animation(.spring(response: 0.35, dampingFraction: 1), value: viewOffset)
    }

    private var container: some View {
        VStack {
            Spacer()
            if isLargeDisplay {
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
            cornerSize: .init(width: corners, height: corners),
            style: .continuous
        )
    }

    private var card: some View {
        VStack(alignment: .trailing, spacing: 0) {
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

            HStack {
                Spacer()
                content()
                    .padding([.horizontal, .bottom], 14)
                Spacer()
            }
        }
        .padding(innerPadding)
        .background(cardShape.fill(style))
        .clipShape(cardShape)
        .offset(x: 0, y: viewOffset/pow(2, abs(viewOffset)/500+1))
        .padding(outerPadding)
        .gesture(
            DragGesture()
                .updating($viewOffset) { value, state, transaction in
                    state = value.translation.height
                }
                .onEnded() { value in
                    if value.predictedEndTranslation.height > 175 {
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

extension View {
    public func slideOverCard<Content: View>(
        onDismiss: (() -> Void)? = nil,
        @ViewBuilder content: @escaping () -> Content
    ) -> some View {
        return ZStack {
            self
            ModalCardContainer(
                onDismiss: onDismiss
            ) {
                content()
            }
        }
    }
}

struct ModalCardView_Previews: PreviewProvider {
    static var previews: some View {
        ModalCardContainer() {
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
