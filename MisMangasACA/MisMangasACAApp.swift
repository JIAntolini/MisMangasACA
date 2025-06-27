//
//  MisMangasACAApp.swift
//  MisMangasACA
//
//  Created by Juan Ignacio Antolini on 19/06/2025.
//

import SwiftUI
import SwiftData
import Combine

@main
struct MisMangasACAApp: App {

    /// Contenedor de modelos compartido para toda la app
    /// Incluye todas las entidades SwiftData que ya definimos.
    /// Se crea una única vez y se inyecta con `.modelContainer(_:)`.
    private var sharedModelContainer: ModelContainer = {
        // ⛑️ Mantén esta lista sincronizada con tus @Model existentes
        let schema = Schema([
            UserCollectionEntry.self,
            MangaEntity.self,
            GenreEntity.self,
            ThemeEntity.self,
            DemographicEntity.self,
            AuthorEntity.self
        ])

        let configuration = ModelConfiguration(schema: schema) // persistido en disco

        do {
            return try ModelContainer(for: schema,
                                      configurations: [configuration])
        } catch {
            fatalError("❌ Could not create ModelContainer: \(error)")
        }
    }()

    @StateObject private var authorsVM = AuthorsViewModel()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(authorsVM)
                .task { await authorsVM.loadAuthors() }
        }
        .modelContainer(sharedModelContainer)
    }
}
