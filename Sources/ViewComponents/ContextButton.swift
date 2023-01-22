//
//  ContextButton.swift
//  
//
//  Created by ErrorErrorError on 1/8/23.
//  
//

import SwiftUI
import Kingfisher
import Foundation

#if os(macOS)
import AppKit
#endif

private let iconSize = CGSize(width: 18, height: 18)

public struct ContextButtonItem: Equatable {
    let name: String
    let image: URL?

    public init(
        name: String,
        image: URL? = nil
    ) {
        self.name = name
        self.image = image
    }
}

public struct ContextButton<Label: View>: View {
    #if os(macOS)
    @StateObject private var menu = MenuObservable()
    #endif

    let items: [ContextButtonItem]
    let label: () -> Label
    let action: ((String) -> ())?

    public init(
        items: [ContextButtonItem],
        action: ((String) -> ())? = nil,
        @ViewBuilder label: @escaping () -> Label
    ) {
        self.items = items
        self.label = label
        self.action = action
    }

    public var body: some View {
        #if os(iOS)
        Menu(content: {
            ForEach(items, id: \.name) { item in
                Button {
                    action?(item.name)
                } label: {
                    Text(item.name)
                    KFImage(item.image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: iconSize.width, height: iconSize.height)
                }
            }
        }, label: label)
        .foregroundColor(.white)
        #else
        label()
            .background(
                GeometryReader { geometryProxy in
                    Spacer()
                        .onChange(of: geometryProxy.frame(in: .global)) { newValue in
                            menu.frame = newValue
                        }
                }
            )
            .onTapGesture {
                menu.showMenu.toggle()
            }
            .onChange(of: items) {
                menu.populateMenu(items: $0)
            }
            .onAppear {
                menu.callback = action
                menu.populateMenu(items: items)
            }
        #endif
    }
}

#if os(macOS)

private class MenuObservable: NSObject, ObservableObject, NSMenuDelegate {
    @Published var showMenu = false {
        didSet { showMenuPopup(showMenu) }
    }

    var frame: CGRect = .zero
    var callback: ((String) -> ())? = nil

    private let menu = NSMenu()

    override init() {
        super.init()
        menu.delegate = self
    }

    func populateMenu(items: [ContextButtonItem]) {
        menu.removeAllItems()

        for item in items {
            let menuItem = NSMenuItem(title: item.name, action: #selector(handlePress), keyEquivalent: "")
            menuItem.representedObject = item
            menuItem.target = self
            if let imageURL = item.image {
                menuItem.image = ImageCache.default.retrieveImageInMemoryCache(forKey: imageURL.absoluteString)

                if menuItem.image == nil {
                    let imageView = KFCrossPlatformImageView()
                    imageView.kf.setImage(with: imageURL)

                    menuItem.image = imageView.image
                }

                menuItem.image = menuItem.image?.kf.resize(to: iconSize, for: .aspectFit)
            }
            menu.addItem(menuItem)
        }
    }

    private func showMenuPopup(_ show: Bool) {
        if show {
            let windowPosition = NSApplication.shared.mainWindow?.frame ?? .zero
            let point = windowPosition.origin.applying(
                .init(
                    translationX: frame.origin.x,
                    y: windowPosition.size.height - frame.origin.y
                )
            )
            menu.popUp(
                positioning: nil,
                at: point,
                in: nil
            )
        }
    }

    func menuDidClose(_ menu: NSMenu) {
        showMenu = false
    }

    @objc func handlePress(_ sender: Any?) {
        guard let menuItem = sender as? NSMenuItem else {
            return
        }

        guard let item = menuItem.representedObject as? ContextButtonItem else {
            return
        }

        DispatchQueue.main.async { [weak self] in
            self?.callback?(item.name)
        }
    }
}

#endif
