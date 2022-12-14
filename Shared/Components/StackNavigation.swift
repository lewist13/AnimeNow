//
//  StackNavigation.swift
//  Anime Now! (iOS)
//
//  Created by ErrorErrorError on 11/22/22.
//  
//

import SwiftUI
import OrderedCollections

struct StackNavigation<Buttons: View, Content: View>: View {
    var title: String = ""
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

extension StackNavigation where Buttons == EmptyView {
    init(
        title: String,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.title = title
        self.content = content
    }
}

struct StackNavigationLink: View {
    var title: String
    var label: () -> AnyView
    var destination: () -> AnyView

    init<Label: View, Destination: View>(
        title: String,
        @ViewBuilder label: @escaping () -> Label,
        @ViewBuilder destination: @escaping () -> Destination
    ) {
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
        .buttonStyle(.plain)
        #else
        label()
            .onTapGesture {
                withAnimation {
                    stack.push(self)
                }
            }
        #endif
    }
}

class StackNavigationObservable: ObservableObject {
    @Published var stack = Array<StackNavigationLink>()

    func push(_ view: StackNavigationLink) {
        stack.append(view)
    }

    func pop() {
        if stack.count > 0 {
            stack.removeLast()
        }
    }

    func last() -> StackNavigationLink? {
        stack.last
    }
}
