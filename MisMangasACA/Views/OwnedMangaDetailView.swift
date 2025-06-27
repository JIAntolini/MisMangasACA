//
//  OwnedMangaDetailView.swift
//  MisMangasACA
//
//  Created by Juan Ignacio Antolini on 22/06/2025.
//  Vista de detalle y edición para un manga de la colección local.
//

import SwiftUI
import SwiftData      // Necesario para `@Bindable`

struct OwnedMangaDetailView: View {

    /// Entrada persistente de la colección que estamos editando.
    @Bindable var entry: UserCollectionEntry

    var body: some View {
        Form {
            // Portada y título
            Section {
                if let urlString = entry.coverURL,
                   let url = URL(string: urlString) {
                    AsyncImage(url: url) { image in
                        image.resizable()
                            .scaledToFit()
                            .cornerRadius(12)
                            .frame(maxWidth: .infinity)
                    } placeholder: {
                        Color.gray.frame(height: 220)
                            .cornerRadius(12)
                    }
                }

                Text(entry.title)
                    .font(.title.bold())
            }

            // Datos de colección
            Section(header: Text("Colección")) {
                Toggle("Colección completa", isOn: $entry.completeCollection)

                // Leyendo tomo
                Stepper(value: Binding(
                    get: { entry.readingVolume ?? 0 },
                    set: { entry.readingVolume = $0 }
                ), in: 0...999) {
                    Text("Leyendo tomo: \(entry.readingVolume ?? 0)")
                }

                // Tomos poseídos (solo lectura por ahora)
                if !entry.volumesOwned.isEmpty {
                    Text("Tomos comprados: \(entry.volumesOwned.map(String.init).sorted().joined(separator: ", "))")
                        .font(.subheadline)
                } else {
                    Text("Aún no tienes tomos cargados.")
                        .foregroundColor(.secondary)
                }
            }
        }
        .navigationTitle(entry.title)
        .navigationBarTitleDisplayMode(.inline)
    }
}
