//  SettingsView+macOS.swift
//  Anime Now! (macOS)
//
//  Created by ErrorErrorError on 12/20/22.
//

#if os(macOS)
import SwiftUI
import ComposableArchitecture

public struct SettingsView: View {
    let store: StoreOf<SettingsReducer>

    public init(
        store: StoreOf<SettingsReducer>
    ) {
        self.store = store
    }

    public var body: some View {
        TabView {
            VStack {
                
            }
            .tabItem {
                Label("General", systemImage: "gearshape.fill")
            }
        }
        .frame(width: 450, height: 250)
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView(
            store: .init(
                initialState: .init(),
                reducer: EmptyReducer()
            )
        )
    }
}
#endif
