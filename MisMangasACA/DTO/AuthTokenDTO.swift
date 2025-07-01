//
//  AuthTokenDTO.swift
//  MisMangasACA
//

import Foundation

/// # AuthTokenDTO
///
/// Data Transfer Object que encapsula las credenciales devueltas por el
/// endpoint de autenticación (`/auth/login`).
///
/// ## Overview
/// - Conforma a `Decodable`.
/// - Mapea los campos `token`, `refreshToken` y `expiresIn` del JSON.
/// - Si el backend usa nombres distintos, ajusta el enum `CodingKeys`.
///
/// ## JSON Example
/// ```json
/// {
///   "token": "eyJhbGciOiJIUzI1NiIsInR...",
///   "refreshToken": "5e3410c5-…",
///   "expiresIn": 3600
/// }
/// ```
///
/// ## Usage
/// ```swift
/// let dto = try decoder.decode(AuthTokenDTO.self, from: data)
/// session.save(token: dto.token, refresh: dto.refreshToken)
/// ```
///
/// ## See Also
/// - ``APIService``
///
/// ## Author
/// Creado por Juan Ignacio Antolini — 2025
///
struct AuthTokenDTO: Decodable {
    let token: String           // si Postman devuelve “token”
    let refreshToken: String?
    let expiresIn: Int?

    private enum CodingKeys: String, CodingKey {
        case token              // ajusta si el campo se llama distinto
        case refreshToken, expiresIn
    }
}
