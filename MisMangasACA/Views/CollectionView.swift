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
                                if let urlString = entry.coverURL,
                                   let sanitized = Optional(urlString.trimmingCharacters(in: CharacterSet(charactersIn: "\""))),
                                   let url = URL(string: sanitized) {
                                    AsyncImage(url: url) { phase in
                                        switch phase {
                                        case .success(let image):
                                            image.resizable()
                                                 .scaledToFill()
                                        default:
                                            Color.gray.opacity(0.3)
                                        }
                                    }
                                    .frame(width: 60, height: 90)
                                    .clipShape(RoundedRectangle(cornerRadius: 6))
                                } else {
                                    // Placeholder cuando no hay portada
                                    Color.gray.opacity(0.3)
                                        .frame(width: 60, height: 90)
                                        .clipShape(RoundedRectangle(cornerRadius: 6))
                                }
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
