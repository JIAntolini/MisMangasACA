//
//  AuthorDTO.swift
//  MisMangasACA
//
//  Modelo que representa un autor tal como lo devuelve la API (/list/authors).
//  Incluye comentarios en español sobre cada campo.
//

import Foundation

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
