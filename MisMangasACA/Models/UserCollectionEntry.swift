//
//  UserCollectionEntry.swift
//  MisMangasACA
//
//  Created by Juan Ignacio Antolini on 27/06/2025.
//


import Foundation
import SwiftData

/// # UserCollectionEntry
///
/// Representa un manga dentro de la **colección local** del usuario, persistido con SwiftData.
/// Guarda tanto la referencia al manga remoto (`mangaID`) como el estado de progreso y posesión.
///
/// ## Overview
/// - Persiste la lista de tomos comprados como JSON comprimido en `volumesOwnedBlob`.
/// - Expone `volumesOwned` como propiedad calculada para accesos tipo array.
/// - Registra `readingVolume`, `completeCollection` y `updatedAt`.
///
/// ## Usage
/// ```swift
/// let entry = UserCollectionEntry(
///     mangaID: 42,
///     title: "One Piece",
///     coverURL: "https://…/onepiece.jpg",
///     volumesOwned: [1,2,3,4],
///     readingVolume: 4,
///     completeCollection: false
/// )
/// context.insert(entry)
/// try context.save()
/// ```
///
/// ## Persistence Details
/// | Propiedad | Uso | Persistencia |
/// |-----------|-----|--------------|
/// | `id` | UUID único | `.unique` |
/// | `volumesOwnedBlob` | JSON binario comprimido | `.externalStorage` |
/// | `updatedAt` | Marca de tiempo | Actualizada manualmente |
///
/// ## See Also
/// - ``MangaEntity``
/// - ``APIService``
///
@Model
final class UserCollectionEntry {
    // MARK: - Propiedades básicas
    
    /// Identificador único de la entrada en la base local.
    @Attribute(.unique) var id: UUID
    
    /// Identificador del manga en la API remota.
    var mangaID: Int
    
    /// Título del manga (se guarda para evitar consultas extras).
    var title: String
    
    /// URL de la portada (texto plano para `AsyncImage`).
    var coverURL: String?
    
    // MARK: - Datos de la colección
    
    /// Blob persistente que guarda el array encodificado como JSON.
    @Attribute(.externalStorage) private var volumesOwnedBlob: Data?

    /// Acceso de conveniencia (no persistente) que codifica/decodifica automáticamente
    /// el array de tomos.  Usa JSON para simplicidad.
    var volumesOwned: [Int] {
        get {
            guard
                let data = volumesOwnedBlob,
                let array = try? JSONDecoder().decode([Int].self, from: data)
            else { return [] }
            return array
        }
        set {
            volumesOwnedBlob = try? JSONEncoder().encode(newValue)
        }
    }
    
    /// Tomo por el que va leyendo (opcional).
    var readingVolume: Int?
    
    /// Indica si el usuario tiene la colección completa.
    var completeCollection: Bool
    
    // MARK: - Metadatos
    
    /// Fecha de la última modificación del registro.
    var updatedAt: Date
    
    // MARK: - Inicializador
    
    init(
        mangaID: Int,
        title: String,
        coverURL: String? = nil,
        volumesOwned: [Int] = [],
        readingVolume: Int? = nil,
        completeCollection: Bool = false,
        updatedAt: Date = .now
    ) {
        self.id = UUID()
        self.mangaID = mangaID
        self.title = title
        self.coverURL = coverURL
        // Codificamos el array directamente para evitar usar `self` antes de tiempo
        self.volumesOwnedBlob = try? JSONEncoder().encode(volumesOwned)
        self.readingVolume = readingVolume
        self.completeCollection = completeCollection
        self.updatedAt = updatedAt
    }
}
