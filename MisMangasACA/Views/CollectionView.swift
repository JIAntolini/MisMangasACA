//
//  CollectionView.swift
//  MisMangasACA
//
//  Created by Juan Ignacio Antolini on 22/06/2025.
//


import SwiftUI
import SwiftData

struct CollectionView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \UserCollectionEntry.title) var entries: [UserCollectionEntry]

    var body: some View {
        NavigationStack {
            List {
                if entries.isEmpty {
                    ContentUnavailableView("Aún no tienes mangas en tu colección", systemImage: "books.vertical")
                } else {
                    ForEach(entries) { entry in
                        NavigationLink(destination: OwnedMangaDetailView(entry: entry)) {
                            HStack(alignment: .top, spacing: 12) {
                                AsyncImage(url: URL(string: entry.coverURL ?? "")) { image in
                                    image.resizable()
                                        .scaledToFill()
                                } placeholder: {
                                    Color.gray
                                }
                                .frame(width: 60, height: 90)
                                .clipped()
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(entry.title)
                                        .font(.headline)
                                    if entry.completeCollection {
                                        Text("Colección completa")
                                            .font(.footnote)
                                            .foregroundColor(.green)
                                    }
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    .onDelete(perform: delete)
                }
            }
            .navigationTitle("Mi colección")
            .toolbar {
                EditButton()
            }
        }
    }

    // Elimina mangas seleccionados de la colección
    func delete(at offsets: IndexSet) {
        for index in offsets {
            let entry = entries[index]
            modelContext.delete(entry)
        }
        try? modelContext.save()
    }
}
