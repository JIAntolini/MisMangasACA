//
//  MisMangasACAApp.swift
//  MisMangasACA
//
//  Created by Juan Ignacio Antolini on 19/06/2025.
//

import SwiftUI
import SwiftData
import Combine

/// # MisMangasACAApp
///
/// Punto de entrada de la aplicación **MisMangasACA**.
/// Configura el contenedor de modelos de SwiftData, inyecta dependencias
/// de alto nivel y muestra la vista raíz.
///
/// ## Overview
/// - Crea un único `ModelContainer` con las entidades de dominio:
///   ``UserCollectionEntry`` / ``MangaEntity`` / ``GenreEntity`` / ``ThemeEntity`` / ``DemographicEntity`` / ``AuthorEntity``
/// - Inyecta el contenedor a toda la jerarquía con `.modelContainer(_:)`.
/// - Carga la lista de autores al lanzamiento y la pone en el ambiente
///   mediante ``AuthorsViewModel``.
///
/// ## Scene Graph
/// ```mermaid
/// flowchart TD
///     A[MisMangasACAApp] --> B(RootView)
///     B --> C[TabView / NavigationStack]
///     B --> D[AuthorsView]:::env
///     classDef env fill:#dff9fb,stroke:#7bed9f;
/// ```
///
/// ## Dependency Injection
/// `@EnvironmentObject`:
/// - ``AuthorsViewModel`` – disponible en toda la app.
///
/// ## See Also
/// - ``RootView``
/// - ``AuthorsViewModel``
///
/// ## Author
/// Creado por Juan Ignacio Antolini — 2025
///
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
