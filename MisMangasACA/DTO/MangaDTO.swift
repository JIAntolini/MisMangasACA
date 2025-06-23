//
//  MangaDTO.swift
//  MisMangasACA
//
//  Estructuras que representan tal cual el JSON de la API
//  Data Transfer Object para mangas, usado en la capa de red.

import Foundation

// MARK: - MangaDTO
public struct MangaDTO: Decodable {
    let id: Int
    let title: String
    let titleJapanese: String?
    let titleEnglish: String?       // Nuevo campo
    let synopsis: String?           // Nombre corregido; el JSON lo envía con typo
    let chapters: Int?
    let volumes: Int?
    let score: Double?
    let status: String?             // “finished”, “publishing”, etc.
    let startDate: Date?
    let endDate: Date?
    let mainPicture: String?
    let background: String?         // Texto largo con descripción histórica
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
