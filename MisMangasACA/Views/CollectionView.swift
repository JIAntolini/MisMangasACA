//
//  CollectionView.swift
//  MisMangasACA
//
//  Created by Juan Ignacio Antolini on 22/06/2025.
//


import SwiftUI
import SwiftData

struct CollectionView: View {
    @Query(sort: \MangaEntity.title) var mangas: [MangaEntity]

    var body: some View {
        NavigationStack {
            List {
                if mangas.isEmpty {
                    ContentUnavailableView("Aún no tienes mangas en tu colección", systemImage: "books.vertical")
                } else {
                    ForEach(mangas) { manga in
                        NavigationLink(destination: OwnedMangaDetailView(manga: manga)) {
                            HStack(alignment: .top, spacing: 12) {
                                AsyncImage(url: manga.coverURL) { image in
                                    image.resizable()
                                        .scaledToFill()
                                } placeholder: {
                                    Color.gray
                                }
                                .frame(width: 60, height: 90)
                                .clipped()
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(manga.title)
                                        .font(.headline)
                                    if let score = manga.score {
                                        Text("⭐️ \(String(format: "%.1f", score))")
                                            .font(.subheadline)
                                    }
                                    if manga.completeCollection {
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
            let manga = mangas[index]
            manga.modelContext?.delete(manga)
        }
    }
}
