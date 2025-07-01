//
//  AuthorsViewModel.swift
//  MisMangasACA
//
//  Created by Juan Ignacio Antolini on 21/06/2025.
//


import Foundation

/// # AuthorsViewModel
///
/// Maneja la lógica de la vista **Autores**: descarga el listado completo,
/// aplica búsqueda local / remota y gestiona la paginación incremental.
///
/// ## Overview
/// - Consume ``APIService`` para `fetchAllAuthors()` y `searchAuthors(_:)`.
/// - Expone `displayedAuthors` calculado según `searchText` y `currentPage`.
/// - Soporta “infinite scroll” con ``loadNextPageIfNeeded(currentItem:)``.
///
/// ## Usage
/// ```swift
/// @StateObject var vm = AuthorsViewModel()
///
/// var body: some View {
///     AuthorsView()
///         .environmentObject(vm)
///         .task { await vm.loadAuthors() }
/// }
/// ```
///
/// ## Topics
/// ### Carga
/// - ``loadAuthors(forceReload:)``
/// - ``searchAuthorsRemotely(_:)``
///
/// ### Paginación
/// - ``loadNextPage()``
/// - ``loadNextPageIfNeeded(currentItem:)``
///
/// ### Helpers
/// - ``displayedAuthors``
///
/// ## See Also
/// - ``AuthorDTO``
/// - ``APIService``
///
/// ## Author
/// Creado por Juan Ignacio Antolini — 2025
///
@MainActor
final class AuthorsViewModel: ObservableObject {
    @Published var authors: [AuthorDTO] = []
    @Published var isLoading = false
    @Published var error: String?
    @Published var searchText: String = "" {
        didSet {
            currentPage = 1
        }
    }

    private let pageSize = 10
    @Published private(set) var currentPage = 1

    var displayedAuthors: [AuthorDTO] {
        let filtered = searchText.isEmpty
            ? authors
            : authors.filter {
                ($0.firstName.lowercased().contains(searchText.lowercased())) ||
                ($0.lastName?.lowercased().contains(searchText.lowercased()) ?? false)
            }
        return Array(filtered.prefix(currentPage * pageSize))
    }

    func loadAuthors(forceReload: Bool = false) async {
        // Si ya hay autores y no se pide recarga forzada, no vuelvas a pedirlos
        if !forceReload && !authors.isEmpty { return }
        isLoading = true
        defer { isLoading = false }
        do {
            authors = try await APIService.shared.fetchAllAuthors()
            // Ordena por apellido, luego por nombre (maneja nils de forma segura)
            authors.sort {
                let lhs = ($0.lastName?.lowercased() ?? "") + $0.firstName.lowercased()
                let rhs = ($1.lastName?.lowercased() ?? "") + $1.firstName.lowercased()
                return lhs < rhs
            }
            currentPage = 1
        } catch {
            self.error = error.localizedDescription
        }
    }
    
    // MARK: – Busca autores por texto usando la API
    /// Busca autores cuyo nombre o apellido contenga el texto, usando el endpoint /search/author/{text}
    func searchAuthorsRemotely(_ text: String) async {
        guard !text.isEmpty else { return }
        isLoading = true
        defer { isLoading = false }
        do {
            authors = try await APIService.shared.searchAuthors(text)
            // Ordena igual que en el fetch general
            authors.sort {
                let lhs = ($0.lastName?.lowercased() ?? "") + $0.firstName.lowercased()
                let rhs = ($1.lastName?.lowercased() ?? "") + $1.firstName.lowercased()
                return lhs < rhs
            }
            currentPage = 1
        } catch {
            self.error = error.localizedDescription
        }
    }
    
    func loadNextPage() {
        currentPage += 1
    }
    
    /// Llama a esto desde la vista cuando el usuario scrollea cerca del final
    func loadNextPageIfNeeded(currentItem: AuthorDTO?) {
        let filtered = searchText.isEmpty
            ? authors
            : authors.filter {
                ($0.firstName.lowercased().contains(searchText.lowercased())) ||
                ($0.lastName?.lowercased().contains(searchText.lowercased()) ?? false)
            }
        guard let currentItem,
              let index = displayedAuthors.firstIndex(where: { $0.id == currentItem.id }),
              index >= displayedAuthors.count - 5,
              displayedAuthors.count < filtered.count
        else { return }
        loadNextPage()
    }
}
