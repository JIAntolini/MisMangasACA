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
    @Published var isLoading = false
    @Published var error: String?

    func loadAuthors() async {
        isLoading = true
        defer { isLoading = false }
        do {
            authors = try await APIService.shared.fetchAllAuthors()
        } catch {
            self.error = error.localizedDescription
        }
    }
}