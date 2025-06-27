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
    @Environment(\.horizontalSizeClass) private var hSize

    var body: some View {
        NavigationStack {
            // Elegimos layout: grid solo en iPad (regular) y cuando hay 5+ items
            Group {
                if hSize == .regular && entries.count >= 5 {
                    gridView
                } else {
                    listView
                }
            }
            .navigationTitle("Mi colección")
            .toolbar { EditButton() }
        }
    }

    // MARK: - List layout (iPhone)
    private var listView: some View {
        List {
            if entries.isEmpty {
                ContentUnavailableView("Aún no tienes mangas en tu colección",
                                       systemImage: "books.vertical")
            } else {
                ForEach(entries) { entry in
                    navigationCell(for: entry, imageSize: .list)
                }
                .onDelete(perform: delete)
            }
        }
    }

    // MARK: - Grid layout (iPad)
    private var gridView: some View {
        ScrollView {
            let cols = [GridItem(.adaptive(minimum: 150), spacing: 16)]
            LazyVGrid(columns: cols, spacing: 16) {
                ForEach(entries) { entry in
                    navigationCell(for: entry, imageSize: .grid)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 24)   // más espacio bajo el título
        }
    }

    // MARK: - Reusable cell
    @ViewBuilder
    private func navigationCell(for entry: UserCollectionEntry,
                                imageSize: CellImageSize) -> some View {
        NavigationLink(destination: OwnedMangaDetailView(entry: entry)) {
            switch imageSize {
            case .list:
                HStack(alignment: .top, spacing: 12) {
                    coverImage(for: entry)
                        .frame(width: 60, height: 90)
                    VStack(alignment: .leading, spacing: 4) {
                        Text(entry.title).font(.headline)
                        if entry.completeCollection {
                            Text("Colección completa")
                                .font(.footnote)
                                .foregroundColor(.green)
                        }
                    }
                }
                .padding(.vertical, 4)

            case .grid:
                VStack(alignment: .leading, spacing: 6) {
                    coverImage(for: entry)
                        .frame(height: 180)
                    Text(entry.title)
                        .font(.headline)
                        .lineLimit(2)
                    if entry.completeCollection {
                        Text("Completo")
                            .font(.caption)
                            .foregroundColor(.green)
                    }
                }
            }
        }
    }

    private enum CellImageSize { case list, grid }

    @ViewBuilder
    private func coverImage(for entry: UserCollectionEntry) -> some View {
        if let urlString = entry.coverURL?
                .trimmingCharacters(in: CharacterSet(charactersIn: "\"")),
           let url = URL(string: urlString) {
            AsyncImage(url: url) { phase in
                switch phase {
                case .success(let image):
                    image.resizable().scaledToFill()
                default:
                    Color.gray.opacity(0.3)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 6))
        } else {
            Color.gray.opacity(0.3)
                .clipShape(RoundedRectangle(cornerRadius: 6))
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
