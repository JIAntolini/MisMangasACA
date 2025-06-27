//
//  CollectionViewModel.swift
//  MisMangasACA
//
//  Created by Juan Ignacio Antolini on 27/06/2025.
//  View‑model centralizado para la colección local del usuario.
//
//  ✅ Maneja carga, borrado y edición de `UserCollectionEntry`
//  ✅ Separa la lógica de datos de la capa de UI (principio DRY)
//  ✅ Comentarios en español para facilitar mantenimiento
//

import Foundation
import SwiftData
import Observation   // Para `@Observable` (iOS 17+) o `@MainActor`

@MainActor
@Observable
final class CollectionViewModel {

    // MARK: - Propiedades

    /// Referencia al `ModelContext` inyectado desde la vista.
    private let context: ModelContext

    /// Entradas de la colección ordenadas alfabéticamente por título.
    private(set) var entries: [UserCollectionEntry] = []
    
    // MARK: - Init

    init(context: ModelContext) {
        self.context = context
        loadEntries()
    }

    // MARK: - Carga

    /// Carga todas las entradas persistentes y las asigna a `entries`.
    func loadEntries() {
        let descriptor = FetchDescriptor<UserCollectionEntry>(
            sortBy: [SortDescriptor(\.title, order: .forward)]
        )
        do {
            entries = try context.fetch(descriptor)
        } catch {
            print("❌ Error cargando entradas:", error)
            entries = []
        }
    }

    // MARK: - Escritura

    /// Elimina permanentemente una entrada y refresca la lista.
    func delete(_ entry: UserCollectionEntry) {
        context.delete(entry)
        saveAndReload()
    }

    /// Actualiza los campos editables de una entrada existente.
    func update(
        entry: UserCollectionEntry,
        volumesOwned: [Int],
        readingVolume: Int?,
        completeCollection: Bool
    ) {
        entry.volumesOwned      = volumesOwned
        entry.readingVolume     = readingVolume
        entry.completeCollection = completeCollection
        entry.updatedAt         = .now
        saveAndReload()
    }

    // MARK: - Helpers

    /// Intenta guardar el `ModelContext` y recargar las entradas.
    private func saveAndReload() {
        do {
            try context.save()
        } catch {
            print("❌ Error guardando contexto:", error)
        }
        loadEntries()
    }
}
