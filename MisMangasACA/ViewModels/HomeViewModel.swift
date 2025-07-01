//
// HomeViewModel.swift
// MisMangasACA
//
// Gestiona la lógica de negocio para la pantalla Home:
// carga “best mangas” con paginación infinita.
//

import Foundation
import Combine

/// # HomeViewModel
///
/// `HomeViewModel` orquesta la lógica de negocio de la pantalla **Home**:
/// carga la lista de mangas, gestiona la paginación infinita y aplica filtros avanzados.
///
/// ## Overview
/// - Consume ``APIService`` de forma asíncrona (`async/await`).
/// - Expone estado `@Published` para que la UI se reactive automáticamente.
/// - Soporta cuatro contextos de carga:
///   - *Top* (`/list/bestMangas`)
///   - *Búsqueda simple* (`/search/mangasContains`)
///   - *Por género* (`/list/mangaByGenre`)
///   - *Búsqueda avanzada* (``CustomSearch`` + `/search/manga`)
///
/// ## Usage
/// ```swift
/// @StateObject private var vm = HomeViewModel()
///
/// var body: some View {
///     HomeView(viewModel: vm)
///         .task { await vm.loadPage(1) } // carga inicial
/// }
/// ```
///
/// ## Paging Flow
/// 1. La UI llama ``loadNextPageIfNeeded(currentItem:)`` al aparecer cada celda.
/// 2. El método decide si traer la página siguiente según `currentItem`.
/// 3. Los nuevos resultados se anexan a ``mangas`` y actualizan `currentPage`, `isLastPage`.
///
/// ## Filtering
/// - ``applyFilters(page:)`` combina la selección de la UI en un ``CustomSearch``.
/// - ``resetFilters()`` limpia todos los estados seleccionados y vuelve al *Top*.
///
/// ## Topics
/// ### Carga y Paginación
/// - ``loadPage(_:forceReload:)``
/// - ``loadNextPageIfNeeded(currentItem:)``
///
/// ### Búsqueda
/// - ``searchMangas(with:page:)``
/// - ``suggestMangas(prefix:page:)``
/// - ``advancedSearch(with:page:)``
///
/// ### Catálogos & Géneros
/// - ``loadCatalogs()``
/// - ``loadGenres()``
/// - ``loadMangasByGenre(_:page:forceReload:)``
///
/// ### Helpers
/// - ``resetFilters()``
///
/// ## See Also
/// - ``APIService``
/// - ``MangaDTO``
/// - ``MangaEntity``
///
/// ## Author
/// Creado por Juan Ignacio Antolini — 2025
///
@MainActor
final class HomeViewModel: ObservableObject {
    // Servicio inyectable (por defecto el singleton compartido)
    private let api: APIService

    // MARK: – Entrada
    @Published var mangas: [MangaDTO] = []
    @Published var isLoadingPage = false
    @Published var isLastPage = false
    @Published var currentPage = 1
    // Catálogos de filtros
    @Published var genres: [String] = []
    @Published var demographics: [String] = []
    @Published var themes: [String] = []

    // Filtros seleccionados (UI)
    @Published var selectedGenre: String?
    @Published var selectedDemographies: Set<String> = []
    @Published var selectedThemes: Set<String> = []
    @Published var selectedAuthorsIDs: Set<Int> = []   // usaremos id de AuthorDTO

    /// Texto de búsqueda libre (título) que proviene de la UI de filtros
    @Published var filterSearchText: String = ""

    /// true = “contiene”, false = “empieza por”
    @Published var filterContains: Bool = true
    @Published var totalMangas: Int = 0
    private let perPage = 20
    
    private var canLoadMore: Bool { !isLastPage }
    
    private enum Context {
        case top
        case busqueda(query: String)
        case genero(String)
        case filtros(CustomSearch)
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
            case .filtros(let search):
                await advancedSearch(with: search, page: currentPage + 1)
            }
        }
    }
    // MARK: – Construye búsqueda combinada desde filtros UI y la aplica
    /// Convierte los filtros seleccionados en un `CustomSearch` y dispara la búsqueda.
    func applyFilters(page: Int = 1) async {
        // Si no hay filtros activos, carga el top por defecto
        let anyFilterActive =
            selectedGenre != nil ||
            !selectedDemographies.isEmpty ||
            !selectedThemes.isEmpty  ||
            !selectedAuthorsIDs.isEmpty ||
            !filterSearchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty

        guard anyFilterActive else {
            await loadPage(1, forceReload: true)
            return
        }

        // Construye el objeto de búsqueda
        let search = CustomSearch(
            searchTitle: filterSearchText.isEmpty ? nil : filterSearchText,
            searchAuthorIds: selectedAuthorsIDs.isEmpty ? nil : Array(selectedAuthorsIDs),
            searchAuthorFirstName: nil,
            searchAuthorLastName: nil,
            searchGenres: selectedGenre.map { [$0] },
            searchThemes: selectedThemes.isEmpty ? nil : Array(selectedThemes),
            searchDemographics: selectedDemographies.isEmpty ? nil : Array(selectedDemographies),
            searchContains: filterContains
        )

        context = .filtros(search)
        await advancedSearch(with: search, page: page)
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
    
    // MARK: – Busca mangas cuyo título empieza por un prefijo (autocompletado, opcional)
    /// Sugerencias de mangas cuyo título empieza por el texto (ideal para UX de autocompletar)
    func suggestMangas(prefix: String, page: Int = 1) async {
        guard !prefix.isEmpty else { return }
        isLoadingPage = true
        defer { isLoadingPage = false }
        do {
            let response = try await api.searchMangasBeginsWith(prefix, page: page, per: perPage)
            if page == 1 {
                mangas = response.data
            } else {
                mangas.append(contentsOf: response.data)
            }
            currentPage = page
            isLastPage = response.data.isEmpty
            self.totalMangas = response.metadata.total
        } catch {
            print("Error en suggestMangas: \(error)")
        }
    }
    
    // MARK: – Busca manga por ID exacto (para detalle directo)
    /// Trae el manga por su ID exacto
    func fetchMangaById(_ id: Int) async -> MangaDTO? {
        isLoadingPage = true
        defer { isLoadingPage = false }
        do {
            return try await api.fetchMangaById(id)
        } catch {
            print("Error al buscar manga por ID: \(error)")
            return nil
        }
    }
    
    // MARK: – Búsqueda avanzada multipropósito (CustomSearch)
    /// Búsqueda combinada: por título, autor, géneros, etc.
    /// - Parameters:
    ///   - search: filtros combinados (struct CustomSearch)
    ///   - page: página a buscar
    func advancedSearch(with search: CustomSearch, page: Int = 1) async {
        isLoadingPage = true
        defer { isLoadingPage = false }
        do {
            let response = try await api.customSearch(search, page: page, per: perPage)
            if page == 1 {
                mangas = response.data
            } else {
                mangas.append(contentsOf: response.data)
            }
            currentPage = page
            isLastPage = response.data.isEmpty
            self.totalMangas = response.metadata.total
        } catch {
            print("Error en advancedSearch: \(error)")
        }
    }
    
    // MARK: – Buscar autores por texto (para usar en búsqueda avanzada o autocompletar)
    /// Devuelve autores cuyo nombre o apellido contenga el texto
    func searchAuthors(with text: String) async -> [AuthorDTO] {
        do {
            return try await api.searchAuthors(text)
        } catch {
            print("Error en searchAuthors: \(error)")
            return []
        }
    }
}

// MARK: - Carga de catálogos (géneros, demografías y temáticas)
extension HomeViewModel {
    /// Carga en paralelo los catálogos de filtros y publica los resultados.
    func loadCatalogs() async {
        async let genresTask: [String] = {
            (try? await api.fetchGenres()) ?? []
        }()
        async let demoTask: [String] = {
            (try? await api.fetchDemographics()) ?? []
        }()
        async let themesTask: [String] = {
            (try? await api.fetchThemes()) ?? []
        }()

        // Espera resultados
        let (genresResult, demoResult, themesResult) = await (genresTask, demoTask, themesTask)

        // Publica en el MainActor (estamos ya en @MainActor)
        self.genres = genresResult
        self.demographics = demoResult
        self.themes = themesResult
    }

    /// Utilidad para resetear los filtros cuando el usuario pulsa "Limpiar"
    func resetFilters() {
        selectedGenre = nil
        selectedDemographies.removeAll()
        selectedThemes.removeAll()
        selectedAuthorsIDs.removeAll()
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
