//
//  AuthorsViewModel.swift
//  MisMangasACA
//
//  Created by Juan Ignacio Antolini on 21/06/2025.
//


import Foundation

@MainActor
final class AuthorsViewModel: ObservableObject {
    @Published var authors: [AuthorDTO] = []
    @Published var displayedAuthors: [AuthorDTO] = []
    @Published var isLoading = false
    @Published var error: String?

    private let pageSize = 10
    private var currentPage = 0

    func loadAuthors() async {
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
            displayedAuthors = Array(authors.prefix(pageSize))
            currentPage = 1
        } catch {
            self.error = error.localizedDescription
        }
    }
    
    func loadNextPage() {
        let start = displayedAuthors.count
        let end = min(authors.count, start + pageSize)
        guard start < end else { return }
        displayedAuthors.append(contentsOf: authors[start..<end])
        currentPage += 1
    }
    
    /// Llama a esto desde la vista cuando el usuario scrollea cerca del final
    func loadNextPageIfNeeded(currentItem: AuthorDTO?) {
        guard let currentItem,
              let index = displayedAuthors.firstIndex(where: { $0.id == currentItem.id }),
              index >= displayedAuthors.count - 5
        else { return }
        loadNextPage()
    }
}
