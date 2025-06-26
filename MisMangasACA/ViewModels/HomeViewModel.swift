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
    @Published var totalMangas: Int = 0
    private let perPage = 20
    
    private var canLoadMore: Bool { !isLastPage }
    
    private enum Context {
        case top
        case busqueda(query: String)
        case genero(String)
    }
    private var context: Context = .top
    
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
        if mangas.last?.id == item.id && !isLoadingPage && !isLastPage {
            switch context {
            case .top:
                await loadPage(currentPage + 1)
            case .busqueda(let query):
                await searchMangas(with: query, page: currentPage + 1)
            case .genero(let genero):
                await loadMangasByGenre(genero, page: currentPage + 1)
            }
        }
    }
    
    func loadPage(_ page: Int, forceReload: Bool = false) async {
        context = .top
        guard (!isLoadingPage && !isLastPage) || forceReload else { return }
        isLoadingPage = true
        defer { isLoadingPage = false }
        
        do {
            let response = try await api.fetchBestMangas(
                page: page,
                per: perPage
            )
            if page == 1 || forceReload {
                mangas = response.data
            } else if page == currentPage + 1 {
                mangas.append(contentsOf: response.data)
            } else {
                mangas = response.data
            }
            currentPage = response.metadata.page
            isLastPage  = response.data.isEmpty
            self.totalMangas = response.metadata.total
        } catch let decodingError as DecodingError {
            // 🛑 Error de decodificación: probablemente shape inesperado del JSON
            print("❌ Decoding error:", decodingError)
            // Evita un loop infinito intentando la misma página
            isLastPage = true
        } catch let urlError as URLError where urlError.code == .cancelled {
            // Ignorar cancelaciones (como al navegar a otra vista)
        } catch {
            print("Error loading page \(page): \(error)")
        }
    }
    /// Busca mangas cuyo título contenga el texto dado, usando el endpoint de la API.
    /// Si la consulta está vacía, recarga el listado de best mangas.
    func searchMangas(with query: String, page: Int = 1) async {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            // Si la búsqueda está vacía, mostramos el top inicial
            await loadPage(1)
            return
        }
        context = .busqueda(query: trimmed)
        isLastPage = false
        isLoadingPage = true
        defer { isLoadingPage = false }
        do {
            let response = try await api.searchMangasContains(trimmed, page: page, per: perPage)
            if page == 1 {
                mangas = response.data
            } else {
                mangas.append(contentsOf: response.data)
            }
            currentPage = page
            isLastPage = response.data.isEmpty
            self.totalMangas = response.metadata.total
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
        context = .genero(genre)
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
            self.totalMangas = response.metadata.total
        } catch {
            #if DEBUG
            print("Error al buscar mangas por género: \(error.localizedDescription)")
            #endif
            // Marca como última página para evitar loops infinitos en caso de error grave
            isLastPage = true
        }
    }
}
