//  SettingsRowView.swift
//  Anime Now!
//
//  Created by ErrorErrorError on 12/22/22.
//  
//

import SwiftUI
import Utilities

public struct SettingsRowView<Accessory: View>: View {
    let name: String
    var tapped: (() -> Void)? = nil
    let accessory: (() -> Accessory)?

    private var loading = false
    private var multiSelection = false
    private var cornerRadius = 0.0
    private let height = 64.0

    public var body: some View {
        HStack {
            Text(name)
                .font(.callout.bold())

            Spacer()

            if loading {
                ProgressView()
                    .progressViewStyle(.circular)
            } else if let accessory {
                accessory()
                    .foregroundColor(multiSelection ? nil : .gray)
            }

            if !loading && multiSelection {
                Image(systemName: "chevron.up.chevron.down")
                    .foregroundColor(.gray)
            }
        }
        .padding(.horizontal, height / 4)
        .frame(height: height)
        .font(.callout)
        .foregroundColor(loading ? Color.gray : Color.white)
        .background(Color(white: 0.2))
        .cornerRadius(cornerRadius)
        .contentShape(Rectangle())
        .onTapGesture {
            !loading ? tapped?() : ()
        }
    }
}

public struct SettingsSwitch: View {
    @Binding var on: Bool

    public var body: some View {
        Toggle(isOn: $on) {
            EmptyView()
        }
        .toggleStyle(.switch)
        .foregroundColor(.primaryAccent)
    }
}

extension SettingsRowView {
    public init(
        name: String,
        tapped: (() -> Void)? = nil
    ) where Accessory == EmptyView {
        self.init(
            name: name,
            tapped: tapped,
            accessory: nil
        )
    }

    public init(
        name: String,
        tapped: @escaping () -> Void
    ) where Accessory == Image {
        self.init(
            name: name,
            tapped: tapped
        ) {
            Image(systemName: "chevron.forward")
        }
    }

    public init(
        name: String,
        text: String,
        tapped: (() -> Void)? = nil
    ) where Accessory == Text {
        self.init(
            name: name,
            tapped: tapped
        ) {
            Text(text)
                .font(.footnote.bold())
        }
    }

    public init(
        name: String,
        active: Binding<Bool>
    ) where Accessory == SettingsSwitch {
        self.init(
            name: name,
            tapped: {
                withAnimation {
                    active.wrappedValue.toggle()
                }
            }
        ) {
            SettingsSwitch(on: active)
        }
    }
}

extension SettingsRowView {
    private struct ExpandableListView<T: Equatable & Identifiable, I: View>: ViewModifier {
        let items: [T]
        let onSelected: (T.ID) -> Void
        let itemView: (T) -> I

        @State private var expand = false

        func body(content: Content) -> some View {
            LazyVStack(spacing: 0) {
                content
                    .highPriorityGesture(
                        TapGesture()
                            .onEnded {
                                withAnimation {
                                    expand.toggle()
                                }
                            }
                    )

                Spacer(minLength: 0)
                    .fixedSize()

                if expand {
                    ForEach(items, id: \.id) { item in
                        LazyVStack {
                            Color.gray.opacity(0.25)
                                .frame(maxWidth: .infinity)
                                .frame(height: 1)
                                .padding(.horizontal)

                            itemView(item)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal)
                                .padding(.vertical, 8)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    withAnimation {
                                        expand = false
                                    }
                                    onSelected(item.id)
                                }
                        }
                        .background(Color(white: 0.2))
                    }
                }
            }
        }
    }

    public static func listSelection<T: Equatable & Identifiable & CustomStringConvertible, I: View>(
        name: String,
        selectable: Selectable<T>,
        loading: Bool = false,
        onSelectedItem: @escaping (T.ID) -> Void,
        @ViewBuilder itemView: @escaping (T) -> I
    ) -> some View where Accessory == Text {
        let view = SettingsRowView(
            name: name,
            text: selectable.item?.description ?? ((selectable.items.count > 0) ? "Not Selected" : "Unavailable")
        )
            .multiSelection(selectable.items.count > 1)
            .loading(loading)

        return view
            .modifier(
                ExpandableListView(
                    items: selectable.items,
                    onSelected: onSelectedItem,
                    itemView: itemView
                )
            )
    }
}

extension SettingsRowView {
    public func onTapped(_ callback: @escaping () -> Void) -> Self {
        var view = self
        view.tapped = callback
        return view
    }

    public func multiSelection(_ multiSelection: Bool) -> Self {
        var view = self
        view.multiSelection = multiSelection
        return view
    }

    public func loading(_ isLoading: Bool) -> Self {
        var view = self
        view.loading = isLoading
        return view
    }

    public func cornerRadius(_ cornerRadius: CGFloat = 12.0) -> Self {
        var view = self
        view.cornerRadius = cornerRadius
        return view
    }
}

struct SettingsRowViewV2_Previes: PreviewProvider {
    static var previews: some View {
        SettingsRowView(name: "Yes", active: .constant(true))
    }
}
