//
//  UserCollectionEntry.swift
//  MisMangasACA
//
//  Created by Juan Ignacio Antolini on 27/06/2025.
//


import Foundation
import SwiftData

/// Modelo persistente de SwiftData que representa un manga dentro de la colección local del usuario.
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
    
    /// Array con los números de tomo que posee el usuario.
    var volumesOwned: [Int]
    
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
        self.volumesOwned = volumesOwned
        self.readingVolume = readingVolume
        self.completeCollection = completeCollection
        self.updatedAt = updatedAt
    }
}
