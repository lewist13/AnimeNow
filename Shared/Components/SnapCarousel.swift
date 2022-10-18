//
//  SnapCarousel.swift
//  Anime Now!
//
//  Created by ErrorErrorError on 10/17/22.
//
//  Modified version of https://github.com/manuelduarte077/CustomCarouselList/blob/main/Shared/View/SnapCarousel.swift

import SwiftUI
import Foundation
import IdentifiedCollections

// To for acepting List....
struct SnapCarousel<Content: View, T: Identifiable>: View {

    /// Properties....

    var spacing: CGFloat
    var trailingSpace: CGFloat

    var list: IdentifiedArrayOf<T>
    var content: (T) -> Content

    init(
        spacing: CGFloat = 0,
        trailingSpace: CGFloat = 0,
        items: IdentifiedArrayOf<T>,
        @ViewBuilder content: @escaping (T)->Content
    ) {
        self.list = items
        self.spacing = spacing
        self.trailingSpace = trailingSpace
        self.content = content
    }

    // Offset...
    @GestureState private var offset: CGFloat = 0
    @State private var position: Int = 0

    var body: some View {
        ZStack(
            alignment: .bottom
        ) {
            scrollItems
            indicator
        }
    }
}

extension SnapCarousel {
    @ViewBuilder
    var scrollItems: some View {
        GeometryReader { proxy in

            let width = proxy.size.width - (trailingSpace - spacing)
            let adjustMentWidth = (trailingSpace / 2) - spacing

            HStack (spacing: spacing) {
                ForEach(list) { item in
                    content(item)
                        .frame(width: proxy.size.width - trailingSpace)
                }
            }

            .padding(.horizontal, spacing)
            .offset(x: (CGFloat(position) * -width) + ( position != 0 ? adjustMentWidth : 0 ) + offset)
            .highPriorityGesture(
                DragGesture()
                    .updating($offset, body: { value, out, _ in
                        out = value.translation.width
                    })
                    .onEnded({ value in
                        let offsetX = value.translation.width
                        let progress = -offsetX / width
                        let roundIndex = progress.rounded()

                        let limitedPosition = max(min(position + Int(roundIndex), list.count - 1), 0)

                        position = limitedPosition
                    })
            )
        }
        .animation(.easeInOut, value: offset == 0)
    }
}

extension SnapCarousel {
    @ViewBuilder
    var indicator: some View {
        HStack(spacing: 6) {
            ForEach(
                Array(zip(indicatorStates.indices, indicatorStates)),
                id: \.0.self
            ) { index, state in
                if state != .gone {
                    Circle()
                        .fill(Color.white.opacity(state.selected ? 1 : 0.5))
                        .frame(width: 6, height: 6)
                        .scaleEffect(state.scale)
                }
            }
            .animation(.spring(), value: indicatorStates)
        }
        .padding()
    }

    enum IndicatorState: Hashable {
        case gone
        case smallest
        case small
        case normal
        case selected

        var scale: Double {
            switch self {
            case .gone:
                return 0
            case .smallest:
                return 0.5
            case .small:
                return 0.75
            case .normal:
                return 1.0
            case .selected:
                return 1.4
            }
        }

        var selected: Bool {
            self == .selected
        }
    }

    private var indicatorStates: [IndicatorState] {
        guard list.indices.count > 0 && position >= 0 && position < list.indices.count else {
            return []
        }

        var indicatorStates = [IndicatorState](repeating: .gone, count: list.count)
        let indicatorCount = indicatorStates.count

        let maxIndicators = min(9, max(1, indicatorCount))

        let halfMaxIndicators = Int(floor(Double(maxIndicators) / 2))
        let halfMaxIndicatorsCeil = Int(ceil(Double(maxIndicators) / 2))

        let leftSideCount = position - halfMaxIndicators
        let rightSideCount = position + halfMaxIndicatorsCeil

        let addMissingLeftSideItems = leftSideCount < 0 ? abs(leftSideCount) : 0
        let addMissingRightSideItems = rightSideCount > indicatorCount ? rightSideCount - indicatorCount : 0

        let startIndex = max(leftSideCount - addMissingRightSideItems, 0)
        let endIndex = min(rightSideCount + addMissingLeftSideItems, indicatorCount)

        for index in startIndex..<endIndex {
            if (startIndex == index && leftSideCount == 0) || (startIndex + 1 == index && leftSideCount >= 1) {
                indicatorStates[index] = .small
            } else if startIndex == index && leftSideCount >= 1 {
                indicatorStates[index] = .smallest
            } else if (endIndex - 2 == index && rightSideCount < indicatorCount) || (endIndex - 1 == index && rightSideCount == indicatorCount) {
                indicatorStates[index] = .small
            } else if endIndex - 1 == index && rightSideCount < indicatorCount {
                indicatorStates[index] = .smallest
            } else {
                indicatorStates[index] = .normal
            }
        }

        indicatorStates[position] = .selected

        return indicatorStates
    }
}
