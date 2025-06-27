//
//  SplitLayoutView.swift
//  MisMangasACA
//
//  Created by Juan Ignacio Antolini on 27/06/2025.
//

import SwiftUI

enum SidebarSection: String, CaseIterable, Identifiable {
    case mangas = "Mangas"
    case authors = "Autores"
    case collection = "Colección"

    var id: Self { self }
}

struct SplitLayoutView: View {
    @State private var selection: SidebarSection? = .mangas
    /// Manga seleccionado para mostrar en el panel de detalle (iPad)
    @State private var selectedManga: MangaDTO?

    var body: some View {
        NavigationSplitView {
            List(SidebarSection.allCases, selection: $selection) { section in
                Label(section.rawValue,
                      systemImage: icon(for: section))
            }
            .navigationTitle("Mis Mangas")
        } content: {
            switch selection {
            case .mangas:
                HomeView(selectedManga: $selectedManga)   // se agrega binding
            case .authors:  AuthorsView()
            case .collection: CollectionView()
            case .none:     Text("Selecciona una sección")
            }
        } detail: {
            if let manga = selectedManga {
                DetailView(manga: manga)
            } else {
                WelcomeDetailView()              // placeholder amigable
            }
        }
    }

    private func icon(for section: SidebarSection) -> String {
        switch section {
        case .mangas: "books.vertical"
        case .authors: "person.3"
        case .collection: "books.vertical.fill"
        }
    }
}
