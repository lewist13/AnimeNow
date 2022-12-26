//  SettingsRowView.swift
//  Anime Now!
//
//  Created by ErrorErrorError on 12/22/22.
//  
//

import SwiftUI

protocol SettingsRow: View {
    func onTapped(_ callback: @escaping () -> Void) -> Self
    func cornerRadius(_ cornerRadius: CGFloat) -> Self
}

public struct SettingsRowView<Accessory: View>: SettingsRow {
    let name: String
    var tapped: (() -> Void)? = nil
    let accessory: (() -> Accessory)?

    private var loading = false
    private var multiSelection = false
    private var cornerRadius = 12.0

    public var body: some View {
        HStack {
            Text(name)
                .font(.callout.bold())
                .padding()

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

            Spacer(minLength: 0)
                .fixedSize()
                .padding(.trailing)
        }
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

extension SettingsRowView where Accessory == Text {
    public init(
        name: String,
        text: String,
        tapped: (() -> Void)? = nil
    ) {
        self.name = name
        self.tapped = tapped
        self.accessory = {
            Text(text)
                .font(.footnote.bold())
        }
    }
}

extension SettingsRowView where Accessory == EmptyView {
    public init(
        name: String,
        tapped: (() -> Void)? = nil
    ) {
        self.name = name
        self.tapped = tapped
        self.accessory = nil
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

    public func cornerRadius(_ cornerRadius: CGFloat) -> Self {
        var view = self
        view.cornerRadius = cornerRadius
        return view
    }
}

struct SettingsRowViewV2_Previes: PreviewProvider {
    static var previews: some View {
        SettingsRowView(name: "Test", text: "Hello")
    }
}
