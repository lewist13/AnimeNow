//
//  EditCollectionView.swift
//  Anime Now!
//
//  Created by ErrorErrorError on 11/17/22.
//  
//

import SwiftUI
import SharedModels
import ViewComponents
import ComposableArchitecture

public struct EditCollectionView: View {
    let store: StoreOf<EditCollectionReducer>

    public init(
        store: StoreOf<EditCollectionReducer>
    ) {
        self.store = store
    }

    public var body: some View {
        VStack(alignment: .center, spacing: 25) {
            VStack(spacing: 8) {
                Text("Add to Collections")
                    .font(.title.bold())
                Text("You can add or remove a show from your collections.")
                    .multilineTextAlignment(.center)
                    .foregroundColor(.gray)
            }

            ScrollView(.vertical) {
                LazyVStack(spacing: 8) {
                    WithViewStore(
                        store,
                        observe: { $0 }
                    ) { viewStore in
                        Group {
                            if viewStore.sortedCollections.count > 0 {
                                Text("Collections")
                                    .font(.callout.bold())
                                    .foregroundColor(.gray.opacity(0.85))
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                
                                ForEach(viewStore.sortedCollections) { collection in
                                    collectionItem(collection, animeId: viewStore.animeId)
                                }
                            } else {
                                Text("No Collections Available")
                                    .font(.title3.weight(.medium))
                                    .frame(height: 80)
                            }
                        }
                        .animation(.easeInOut, value: viewStore.state)
                    }
                }
            }
            .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 12)
                .fixedSize()
        }
    }
}

extension EditCollectionView {
    @ViewBuilder
    func collectionItem(
        _ collection: CollectionStore,
        animeId: AnimeStore.ID
    ) -> some View {
        let selected = collection.animes[id: animeId] != nil
        HStack {
            VStack(alignment: .leading) {
                Text(collection.title.value)
                    .font(.body.weight(.medium))
                    .lineLimit(1)
                Text("\(collection.animes.count) Items")
                    .font(.footnote.weight(.medium))
                    .foregroundColor(.gray)
            }
            Spacer()
            Image(systemName: selected ? "checkmark.circle.fill" : "circle")
                .font(.body.bold())
                .foregroundColor(selected ? .secondaryAccent : .init(white: 0.6))
                .imageScale(.large)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 16)
        .background(Color(white: 0.2))
        .cornerRadius(12)
        .contentShape(Rectangle())
        .onTapGesture {
            ViewStore(store).send(.collectionSelectedToggle(collection.id))
        }
    }
}

struct EditCollectionView_Preview: PreviewProvider {
    static var previews: some View {
        ModalCardView {
            EditCollectionView(
                store: .init(
                    initialState: .init(
                        animeId: Anime.attackOnTitan.id
                    ),
                    reducer: EditCollectionReducer()
                )
            )
        }
        .preferredColorScheme(.dark)
    }
}
