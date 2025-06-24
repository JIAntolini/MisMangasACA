//
// HomeViewModel.swift
// MisMangasACA
//
// Gestiona la lógica de negocio para la pantalla Home:
// carga “best mangas” con paginación infinita.
//

import Foundation
import Combine

@MainActor
final class HomeViewModel: ObservableObject {
    // Servicio inyectable (por defecto el singleton compartido)
    private let api: APIService

    // MARK: – Entrada
    @Published var mangas: [MangaDTO] = []
    @Published var isLoadingPage = false
    @Published var isLastPage = false
    @Published var currentPage = 1
    @Published var genres: [String] = []
    @Published var selectedGenre: String?
    private let perPage = 20
    
    private var canLoadMore: Bool { !isLastPage }
    
    // MARK: – Init
    init(api: APIService = .shared) {
        self.api = api
    }
    
    // MARK: – Carga inicial y siguientes páginas
    func loadNextPageIfNeeded(currentItem: MangaDTO?) async {
        guard let item = currentItem else {
            await loadPage(1)
            return
        }
        // Si el ítem actual es el último de la lista y hay más páginas...
        if mangas.last?.id == item.id && !isLoadingPage {
            await loadPage(currentPage + 1)
        }
    }
    
func loadPage(_ page: Int, forceReload: Bool = false) async {
        guard (!isLoadingPage && !isLastPage) || forceReload else { return }
        isLoadingPage = true
        defer { isLoadingPage = false }
        
        do {
            let response = try await api.fetchBestMangas(
                page: page,
                per: perPage
            )
            // 1. Actualiza la lista
            if page == 1 {
                mangas = response.data
            } else {
                mangas.append(contentsOf: response.data)
            }

            // 2. Actualiza el estado de paginación
            currentPage = response.metadata.page
            isLastPage  = response.data.isEmpty
        } catch let decodingError as DecodingError {
            // 🛑 Error de decodificación: probablemente shape inesperado del JSON
            print("❌ Decoding error:", decodingError)
            // Evita un loop infinito intentando la misma página
            isLastPage = true
        } catch {
            // Otros errores: red, URL, etc.
            print("Error loading page \(page): \(error)")
        }
    }
    /// Busca mangas cuyo título contenga el texto dado, usando el endpoint de la API.
    /// Si la consulta está vacía, recarga el listado de best mangas.
    func searchMangas(with query: String) async {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            // Si la búsqueda está vacía, mostramos el top inicial
            await loadPage(1)
            return
        }
        isLoadingPage = true
        defer { isLoadingPage = false }
        do {
            let response = try await api.searchMangasContains(trimmed, page: 1, per: perPage)
            mangas = response.data
            currentPage = 1
            isLastPage = response.data.isEmpty
        } catch {
            print("Error al buscar mangas: \(error)")
            // Opcional: podrías exponer un mensaje de error a la UI aquí
        }
    }
}

// MARK: - Filtro por género (usando String)
extension HomeViewModel {
    /// Carga todos los géneros disponibles desde la API (como array de String)
    func loadGenres() async {
        do {
            genres = try await api.fetchGenres()
        } catch {
            print("Error al cargar géneros: \(error)")
        }
    }

    /// Carga mangas de un género específico usando el endpoint paginado /list/mangaByGenre/{genre}.
    /// Ahora permite paginación infinita e integra el control de página y última página.
    func loadMangasByGenre(_ genre: String, page: Int = 1, forceReload: Bool = false) async {
        guard (!isLoadingPage && !isLastPage) || forceReload else { return }
        isLoadingPage = true
        defer { isLoadingPage = false }

        do {
            // Trae la página solicitada de mangas por género
            let response = try await api.fetchMangasByGenre(genre, page: page, per: perPage)
            if page == 1 || forceReload {
                mangas = response.data
            } else {
                mangas.append(contentsOf: response.data)
            }
            currentPage = response.metadata.page
            // Si no hay más resultados, se marca como última página
            isLastPage = response.data.isEmpty
            selectedGenre = genre
        } catch {
            #if DEBUG
            print("Error al buscar mangas por género: \(error.localizedDescription)")
            #endif
            // Marca como última página para evitar loops infinitos en caso de error grave
            isLastPage = true
        }
    }
}
