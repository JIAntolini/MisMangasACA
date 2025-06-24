//
//  APIService.swift
//  MisMangasACA
//
//  Capa de red: maneja todas las llamadas HTTP a la API REST de MisMangasACA.
//  Usa URLSession nativo, Codable y Swift Concurrency.
//  Incluye un método genérico y funciones específicas como fetchMangas.
//

import Foundation

// MARK: – Modelo de paginación según la especificación
public struct PaginatedResponse<T: Decodable>: Decodable {
    public let data: [T]          // lo seguiremos llamando data internamente
    public let metadata: Metadata

    private enum CodingKeys: String, CodingKey {
        case data     = "items"      // ← mapear items → data
        case metadata
    }

    public struct Metadata: Decodable {
        public let total: Int
        public let page: Int   // ← ahora la propiedad es pública y sin corte
        public let per: Int
    }
}

// MARK: – HTTPMethod para futuras expansiones (POST, DELETE…)
private enum HTTPMethod: String {
    case GET, POST, DELETE, PUT
}

// MARK: – Servicio de API
open class APIService {
    // Sesión inyectable para pruebas (por defecto URLSession.shared)
    private let session: URLSession

    // Init configurable; el singleton usa el valor por defecto
    init(session: URLSession = .shared) {
        self.session = session
    }

    // ▶️ Instancia compartida (singleton)
    static let shared = APIService()   // usa .shared internamente
    
    // 🔑 Token de la app según docs
    private let appToken = "sLGH38NhEJ0_anlIWwhsz1-LarClEohiAHQqayF0FY"
    
    // 🌐 URL base de la API (Postman collection)
    private let baseURL = URL(string: "https://mymanga-acacademy-5607149ebe3d.herokuapp.com")!
    // [Referencia: ver colección Postman para detalles de rutas]


    // MARK: – Método genérico para peticiones GET paginadas o normales
    func request<T: Decodable>(
        path: String,
        queryItems: [URLQueryItem] = []
    ) async throws -> T {
        // 1. Construir URL completo
        var components = URLComponents(url: baseURL.appendingPathComponent(path), resolvingAgainstBaseURL: false)!
        if !queryItems.isEmpty {
            components.queryItems = queryItems
        }

        let urlRequest = buildRequest(url: components.url!, method: .GET)
        
        // 2. Ejecutar petición con URLSession
        let (data, response) = try await session.data(for: urlRequest)
        
        // 3. Verificar estado HTTP
        guard let httpResp = response as? HTTPURLResponse,
              200..<300 ~= httpResp.statusCode else {
            throw URLError(.badServerResponse)
        }
        
        // 4. Decodificar JSON a modelo genérico
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(T.self, from: data)
    }
    
    // Construye la URLRequest con headers comunes
    private func buildRequest(url: URL, method: HTTPMethod) -> URLRequest {
        var req = URLRequest(url: url)
        req.httpMethod = method.rawValue
        // Header obligatorio para identificar la app
        req.setValue(appToken, forHTTPHeaderField: "App-Token")
        return req
    }
    
    // MARK: – Función específica: obtener lista de mangas paginada
    /// - Parameters:
    ///   - page: número de página (1…N)
    ///   - per: items por página (por defecto 10)
    /// - Returns: PaginatedResponse<MangaDTO>
    func fetchMangas(page: Int = 1, per: Int = 10) async throws -> PaginatedResponse<MangaDTO> {
        // Construir query para mantener coherencia per en todas las páginas
        // [oai_citation:2‡Práctica.pdf](file-service://file-U4H44ffK4xdC7GT7AEwHYL)
        let path = "/list/mangas"
        let queries = [
            URLQueryItem(name: "page", value: "\(page)"),
            URLQueryItem(name: "per",  value: "\(per)")
        ]
        return try await request(path: path, queryItems: queries)
    }
    
    // MARK: – Otros endpoints que implementarás igual:
    // MARK: – 1. Top mangas (best)
    /// Obtiene el listado de mangas más populares o recomendados.
    /// - Parameters:
    ///   - page: número de página (1…N)
    ///   - per: elementos por página
    /// - Returns: PaginatedResponse<MangaDTO>
    open func fetchBestMangas(page: Int = 1, per: Int = 10) async throws -> PaginatedResponse<MangaDTO> {
        let path = "/list/bestMangas"
        let queries = [
            URLQueryItem(name: "page", value: "\(page)"),
            URLQueryItem(name: "per",  value: "\(per)")
        ]
        return try await request(path: path, queryItems: queries)
    }

    // MARK: – 2. Búsqueda de mangas por título
    /// Busca mangas cuyo título contenga el texto dado (case-insensitive).
    /// - Parameters:
    ///   - text: texto a buscar en el título
    ///   - page: número de página
    ///   - per: elementos por página
    /// - Returns: PaginatedResponse<MangaDTO>
    func searchMangasContains(_ text: String, page: Int = 1, per: Int = 10) async throws -> PaginatedResponse<MangaDTO> {
        let encoded = text.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? text
        let path = "/search/mangasContains/\(encoded)"
        let queries = [
            URLQueryItem(name: "page", value: "\(page)"),
            URLQueryItem(name: "per",  value: "\(per)")
        ]
        return try await request(path: path, queryItems: queries)
    }

    // MARK: – 3. Listado de géneros
    /// Obtiene la lista de todos los géneros disponibles.
    /// - Returns: array de String
    func fetchGenres() async throws -> [String] {
        return try await request(path: "/list/genres")
    }
    
    /// Obtiene los mangas asociados a un género específico usando el endpoint /list/mangaByGenre/{genre}, con soporte de paginación.
    /// - Parameters:
    ///   - genre: El nombre del género tal como lo devuelve la API, por ejemplo "Action"
    ///   - page: Número de página a solicitar (por defecto 1)
    ///   - per: Cantidad de mangas por página (por defecto 10)
    /// - Returns: PaginatedResponse<MangaDTO> incluyendo la lista de mangas y los metadatos de paginación.
    func fetchMangasByGenre(_ genre: String, page: Int = 1, per: Int = 10) async throws -> PaginatedResponse<MangaDTO> {
        // Convierte el género a snake_case y codifica para la URL
        let snakeCase = genreToSnakeCase(genre)
        let encodedGenre = snakeCase.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? snakeCase
        let path = "/list/mangaByGenre/\(encodedGenre)"
        // Armamos los parámetros de paginación para la URL
        let queries = [
            URLQueryItem(name: "page", value: "\(page)"),
            URLQueryItem(name: "per",  value: "\(per)")
        ]
        // Realiza la petición genérica y retorna la respuesta paginada
        return try await request(path: path, queryItems: queries)
    }
    
    /// Convierte un string de género a snake_case, reemplazando espacios y guiones por guión bajo, y diacríticos por su forma simple.
    private func genreToSnakeCase(_ genre: String) -> String {
        genre
            .lowercased()
            .replacingOccurrences(of: " ", with: "_")
            .replacingOccurrences(of: "-", with: "_")
            .replacingOccurrences(of: "&", with: "and")
            .folding(options: .diacriticInsensitive, locale: .current)
    }

    // MARK: – 4. Listado de autores
    /// Obtiene todos los autores de la base de datos (endpoint /list/authors).
    /// La API devuelve un array de autores (sin paginación).
    /// - Returns: Array de AuthorDTO
    func fetchAllAuthors() async throws -> [AuthorDTO] {
        let path = "/list/authors"
        let url = baseURL.appendingPathComponent(path)
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue(appToken, forHTTPHeaderField: "App-Token")
        
        let (data, response) = try await session.data(for: request)
        guard let httpResp = response as? HTTPURLResponse,
              200..<300 ~= httpResp.statusCode else {
            throw URLError(.badServerResponse)
        }
        
        let decoder = JSONDecoder()
        return try decoder.decode([AuthorDTO].self, from: data)
    }
    // func createUser(email: String, password: String) async throws -> Void { … }
    // func login(email: String, password: String) async throws -> AuthTokenDTO { … }
    // etc.
}
