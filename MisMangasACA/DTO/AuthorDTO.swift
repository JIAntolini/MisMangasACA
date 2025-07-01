//
//  AuthorDTO.swift
//  MisMangasACA
//
//  Modelo que representa un autor tal como lo devuelve la API (/list/authors).
//  Incluye comentarios en español sobre cada campo.
//

import Foundation

/// # AuthorDTO
///
/// Data Transfer Object que representa un **autor** tal como lo devuelve
/// el endpoint `/list/authors`.
///
/// ## Overview
/// - Conforma a `Codable`, `Identifiable` y `Hashable` para uso en listas.
/// - Contiene campos opcionales (`lastName`, `nationality`, `birthYear`, `role`)
///   que pueden venir como `null` en la API.
/// - Incluye el array `mangas` con los IDs de obras asociadas.
///
/// ## JSON Mapping
/// Si la API emplea claves diferentes, define el enum `CodingKeys`.
///
/// ## Usage
/// ```swift
/// let authors = try await api.fetchAllAuthors()
/// print(authors.first?.firstName ?? "")
/// ```
///
/// ## See Also
/// - ``AuthorMangasViewModel``
/// - ``AuthorDTO`` (esta misma estructura)
/// - ``MangaDTO``
///
/// ## Author
/// Creado por Juan Ignacio Antolini — 2025
///
/// Representa un autor de manga en la base de datos.
struct AuthorDTO: Codable, Identifiable, Hashable {
    /// Identificador único del autor (puede ser Int o String según la API; ajusta si es UUID)
    let id: String
    /// Nombre de pila del autor
    let firstName: String
    /// Apellido del autor (puede faltar)
    let lastName: String?
    /// Nacionalidad (puede faltar o venir como null)
    let nationality: String?
    /// Año de nacimiento (puede faltar o venir como null)
    let birthYear: Int?
    /// Lista de IDs de mangas escritos/dibujados por el autor
    let mangas: [Int]?
    /// Rol del autor, si la API lo provee (ej: “Story & Art”)
    let role: String?

    // Si algún campo tiene otro nombre en el JSON, agrega CodingKeys aquí
    // enum CodingKeys: String, CodingKey { ... }
}
