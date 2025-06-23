//
//  AuthTokenDTO.swift
//  MisMangasACA
//

import Foundation

struct AuthTokenDTO: Decodable {
    let token: String           // si Postman devuelve “token”
    let refreshToken: String?
    let expiresIn: Int?

    private enum CodingKeys: String, CodingKey {
        case token              // ajusta si el campo se llama distinto
        case refreshToken, expiresIn
    }
}
