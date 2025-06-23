//
//  MangaEntity.swift
//  MisMangasACA
//
//  SwiftData @Model definitions for the app.
//  Contiene la jerarquía principal: Manga + entidades de catálogo (género, tema, etc.)
//

import Foundation
import SwiftData

// MARK: - IdentifiableDTO
/// Protocolo genérico para todos los DTO que exponen una clave `id`.
/// El tipo concreto (`Int`, `String`, `UUID`, etc.) se define en cada DTO.
protocol IdentifiableDTO {
    associatedtype Identifier: Hashable
    var id: Identifier { get }
}


// MARK: - NamedEntity
/// Entidades de catálogo (géneros, temas, demografías, autores).
/// Cuentan con `id`, `name` y un inicializador que acepta su DTO par.
protocol NamedEntity: PersistentModel, Hashable {
    associatedtype DTOType: IdentifiableDTO
    var id: String  { get set }
    var name: String { get set }

    init(id: String, name: String)
    init(from dto: DTOType)
}

// MARK: – Catálogo de entidades

@Model
final class GenreEntity: NamedEntity {
    var id: String
    var name: String

    @Relationship(inverse: \MangaEntity.genres) var mangas: [MangaEntity] = []

    init(id: String, name: String) { self.id = id; self.name = name }
    convenience init(from dto: GenreDTO) {
        self.init(id: String(describing: dto.id), name: dto.genre)
    }
}

@Model
final class ThemeEntity: NamedEntity {
    var id: String
    var name: String

    @Relationship(inverse: \MangaEntity.themes) var mangas: [MangaEntity] = []

    init(id: String, name: String) { self.id = id; self.name = name }
    convenience init(from dto: ThemeDTO) {
        self.init(id: String(describing: dto.id), name: dto.theme)
    }
}

@Model
final class DemographicEntity: NamedEntity {
    var id: String
    var name: String

    @Relationship(inverse: \MangaEntity.demographics) var mangas: [MangaEntity] = []

    init(id: String, name: String) { self.id = id; self.name = name }
    convenience init(from dto: DemographicDTO) {
        self.init(id: String(describing: dto.id), name: dto.demographic)
    }
}

@Model
final class AuthorEntity: NamedEntity {
    var id: String
    var name: String      // “Nombre Apellido” simplificado

    @Relationship(inverse: \MangaEntity.authors) var mangas: [MangaEntity] = []

    init(id: String, name: String) { self.id = id; self.name = name }
    convenience init(from dto: AuthorDTO) {
        let fullName = [dto.firstName, dto.lastName].compactMap { $0 }.joined(separator: " ")
        self.init(id: String(describing: dto.id), name: fullName)
    }
}

// MARK: - MangaEntity

@Model
final class MangaEntity {

    // Propiedades principales provenientes de la API
    @Attribute(.unique) var id: Int
    var title: String
    var coverURL: URL?
    var score: Double?
    var synopsis: String?

    // Relaciones con entidades de catálogo
    @Relationship(deleteRule: .cascade) var genres: [GenreEntity] = []
    @Relationship(deleteRule: .cascade) var themes: [ThemeEntity] = []
    @Relationship(deleteRule: .cascade) var demographics: [DemographicEntity] = []
    @Relationship(deleteRule: .cascade) var authors: [AuthorEntity] = []

    // Estado del usuario
    var completeCollection: Bool = false
    var volumesOwned: [Int] = []
    var readingVolume: Int?

    // MARK: Inicializadores
    init(id: Int,
         title: String,
         coverURL: URL?,
         score: Double?,
         synopsis: String?) {
        self.id = id
        self.title = title
        self.coverURL = coverURL
        self.score = score
        self.synopsis = synopsis
    }

    /// Convierte un DTO a entidad persistente, re-usando catálogos existentes (principio DRY)
    convenience init(from dto: MangaDTO, context: ModelContext) {
        // Limpia las comillas escapadas y construye un URL válido
        let coverURL: URL? = dto.mainPicture
            .map { $0.replacingOccurrences(of: "\"", with: "") }
            .flatMap { URL(string: $0) }

        self.init(id: dto.id,
                  title: dto.title,
                  coverURL: coverURL,
                  score: dto.score,
                  synopsis: dto.synopsis)

        // Helper genérico para fetch/insert
        func fetchOrInsert<T: NamedEntity>(_ dtoArr: [T.DTOType],
                                           as type: T.Type) -> [T] {
            dtoArr.map { dto in
                let filterID = String(describing: dto.id)
                let predicate = #Predicate<T> { $0.id == filterID }
                let descriptor = FetchDescriptor<T>(predicate: predicate)
                if let existing = try? context.fetch(descriptor).first {
                    return existing
                } else {
                    return T(from: dto)
                }
            }
        }

        self.genres       = fetchOrInsert(dto.genres,       as: GenreEntity.self)
        self.themes       = fetchOrInsert(dto.themes,       as: ThemeEntity.self)
        self.demographics = fetchOrInsert(dto.demographics, as: DemographicEntity.self)
        self.authors      = fetchOrInsert(dto.authors,      as: AuthorEntity.self)
    }

    // MARK: Predicados listos para usar
    static func byID(_ id: Int) -> Predicate<MangaEntity> { #Predicate { $0.id == id } }
    static func search(titleContains text: String) -> Predicate<MangaEntity> {
        #Predicate { $0.title.localizedStandardContains(text) }
    }
}
