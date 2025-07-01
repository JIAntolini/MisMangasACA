//
//  MangaDTO.swift
//  MisMangasACA
//
//  Estructuras que representan tal cual el JSON de la API
//  Data Transfer Object para mangas, usado en la capa de red.

import Foundation

/// # MangaDTO
///
/// Data Transfer Object que refleja la estructura JSON del backend para un **manga**.
/// Se usa exclusivamente en la capa de red y se convierte luego en
/// ``MangaEntity`` para persistencia.
///
/// ## Overview
/// - Conforma a `Decodable` e `Identifiable`.
/// - Corrige claves mal escritas mediante el enum `CodingKeys`.
/// - Agrupa catálogos en sub‐DTOs: ``GenreDTO``, ``ThemeDTO``, ``DemographicDTO``,
///   y los autores en ``AuthorDTO``.
///
/// ## JSON Mapping
/// | Propiedad | Clave JSON | Notas |
/// |-----------|------------|-------|
/// | `titleJapanese` | `"titleJapanese"` | — |
/// | `synopsis` | `"sypnosis"` | Backend typo corregido |
/// | `mainPicture` | `"mainPicture"` | URL |
///
/// ## Usage
/// ```swift
/// let dto = try decoder.decode(MangaDTO.self, from: data)
/// print(dto.title) // Título principal
/// ```
///
/// ## See Also
/// - ``GenreDTO``
/// - ``ThemeDTO``
/// - ``DemographicDTO``
/// - ``AuthorDTO``
/// - ``MangaEntity``
///
/// ## Author
/// Creado por Juan Ignacio Antolini — 2025
///
public struct MangaDTO: Decodable, Identifiable {
    public let id: Int
    let title: String
    let titleJapanese: String?
    let titleEnglish: String?       // Nuevo campo
    let synopsis: String?           // Nombre corregido; el JSON lo envía con typo
    let chapters: Int?
    let volumes: Int?
    let score: Double?
    public let status: String?             // “finished”, “publishing”, etc.
    let startDate: Date?
    let endDate: Date?
    let mainPicture: String?
    let background: String?         // Texto laaargo con descripción histórica
    let url: String?                   // Link externo
    let demographics: [DemographicDTO]
    let genres: [GenreDTO]
    let themes: [ThemeDTO]
    let authors: [AuthorDTO]

    // Mapear claves que difieren del nombre de propiedades
    private enum CodingKeys: String, CodingKey {
        case id, title, chapters, volumes, score, status, background, url
        case titleJapanese, titleEnglish
        case synopsis = "sypnosis"  // El backend lo envía mal escrito
        case startDate, endDate
        case mainPicture
        case demographics, genres, themes, authors
    }
}

// MARK: - Subtipos

struct GenreDTO: Decodable {
    let id: String
    let genre: String

    private enum CodingKeys: String, CodingKey {
        case id, genre
    }
}

 
struct ThemeDTO: Decodable {
    let id: String
    let theme: String

    private enum CodingKeys: String, CodingKey {
        case id, theme
    }
}

struct DemographicDTO: Decodable {
    let id: String
    let demographic: String

    private enum CodingKeys: String, CodingKey {
        case id, demographic
    }
}

/*struct AuthorDTO: Decodable {
    let id: String           // UUID
    let role: String?           // “Story & Art”, etc.
    let firstName: String
    let lastName: String?

    private enum CodingKeys: String, CodingKey {
        case id, role, firstName, lastName
    }
}
*/


extension GenreDTO: IdentifiableDTO { typealias Identifier = String }
extension ThemeDTO: IdentifiableDTO { typealias Identifier = String }
extension DemographicDTO: IdentifiableDTO { typealias Identifier = String }
extension AuthorDTO: IdentifiableDTO { typealias Identifier = String }
extension MangaDTO: IdentifiableDTO { typealias Identifier = Int }

// MARK: – SwiftUI Preview helper
#if DEBUG
extension MangaDTO {
    /// Ejemplo de manga estático para usar en previews
    static let previewSample = MangaDTO(
        id: 1,
        title: "Fullmetal Alchemist",
        titleJapanese: "鋼の錬金術師",
        titleEnglish: "Fullmetal Alchemist",
        synopsis: "Historia de dos hermanos alquimistas que buscan la Piedra Filosofal.",
        chapters: 116,
        volumes: 27,
        score: 9.1,
        status: "finished",
        startDate: Date(timeIntervalSince1970: 978_220_800), // 1‑ene‑2001
        endDate: nil,
        mainPicture: "https://cdn.myanimelist.net/images/manga/3/243675.jpg",
        background: nil,
        url: "https://myanimelist.net/manga/25/Fullmetal_Alchemist",
        demographics: [],
        genres: [],
        themes: [],
        authors: []
    )
}
#endif
