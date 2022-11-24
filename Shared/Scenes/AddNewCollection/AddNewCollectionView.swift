//  AddNewCollectionView.swift
//  Anime Now!
//
//  Created by ErrorErrorError on 11/19/22.
//

import SwiftUI
import ComposableArchitecture

struct AddNewCollectionView: View {
    let store: StoreOf<AddNewCollectionReducer>

    var body: some View {
        VStack(alignment: .center, spacing: 20) {
            VStack(spacing: 8) {
                Text("Create New Collection")
                    .font(.title.bold())
                    .multilineTextAlignment(.center)
            }

            VStack(spacing: 8) {
                Text("Collections")
                    .font(.callout.bold())
                    .foregroundColor(.gray.opacity(0.85))
                    .frame(maxWidth: .infinity, alignment: .leading)

                WithViewStore(store) {
                    TextField("Collection Name", text: $0.binding(\.$title))
                        .textFieldStyle(.plain)
                        .padding(12)
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(12)
                }
            }

            WithViewStore(
                store,
                observe: \.canSave
            ) { viewStore in
                Button {
                    viewStore.send(.saveTitle)
                } label: {
                    Text("Save")
                        .font(.body.bold())
                        .foregroundColor(viewStore.state ? .black : .gray)
                        .frame(maxWidth: .infinity)
                        .padding(16)
                        .background(viewStore.state ? Color.white : Color(white: 0.2))
                        .cornerRadius(8)
                }
                .buttonStyle(.plain)
                .contentShape(Rectangle())
                .disabled(!viewStore.state)
            }
        }
        .onAppear {
            ViewStore(store).send(.onAppear)
        }
    }
}

struct AddNewCollectionView_Previews: PreviewProvider {
    static var previews: some View {
        AddNewCollectionView(
            store: .init(
                initialState: .init(namesUsed: []),
                reducer: AddNewCollectionReducer()
            )
        )
    }
}
