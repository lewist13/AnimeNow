//  StackNavigation.swift
//  Anime Now! (iOS)
//
//  Created by ErrorErrorError on 11/22/22.
//  
//

import SwiftUI
import OrderedCollections

struct StackNavigation<Buttons: View, Content: View>: View {
    let title: String
    var content: () -> Content
    var buttons: (() -> Buttons)? = nil

    @StateObject var stack = StackNavigationObservable()

    var body: some View {
        #if os(iOS)
        NavigationView {
            content()
                .navigationTitle(title)
                .toolbar {
                    buttons?()
                }
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationViewStyle(.stack)
        .onAppear {
            UINavigationBar.appearance().isTranslucent = false
        }
        #else
        VStack {
            if let last = stack.last() {
                HStack {
                    Button {
                        withAnimation {
                            stack.pop()
                        }
                    } label: {
                        Image(systemName: "chevron.left")
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)

                    Spacer()
                    Text(last.title)
                    Spacer()
                }
                .font(.title3.weight(.heavy))
                .padding(.horizontal)
                .padding(.vertical, 8)

                last.destination()
            } else {
                buttons?()
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .padding(.horizontal)
                    .padding(.vertical, 8)

                content()
            }
        }
        .environmentObject(stack)
        #endif
    }
}

struct StackNavigationLink: View {
    var id: AnyHashable
    var title: String
    var label: () -> AnyView
    var destination: () -> AnyView

    init<Label: View, Destination: View>(
        id: AnyHashable,
        title: String,
        @ViewBuilder label: @escaping () -> Label,
        @ViewBuilder destination: @escaping () -> Destination
    ) {
        self.id = id
        self.title = title
        self.label = { AnyView(label()) }
        self.destination = { AnyView(destination()) }
    }

    @EnvironmentObject var stack: StackNavigationObservable

    var body: some View {
        #if os(iOS)
        NavigationLink(
            destination: {
                destination()
                    .navigationTitle(title)
            },
            label: label
        )
        #else
        label()
            .onTapGesture {
                withAnimation {
                    stack.push(id: id, self)
                }
            }
        #endif
    }
}

class StackNavigationObservable: ObservableObject {
    @Published var stack = OrderedDictionary<AnyHashable, StackNavigationLink>()

    func push(id: AnyHashable, _ view: StackNavigationLink) {
        stack[id] = view
    }

    func pop() {
        if stack.count > 0 {
            stack.removeLast()
        }
    }

    func last() -> StackNavigationLink? {
        stack.values.last
    }
}
