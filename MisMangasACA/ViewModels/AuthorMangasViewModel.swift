//
//  AuthorMangasViewModel.swift
//  MisMangasACA
//
//  Created by Juan Ignacio Antolini on 24/06/2025.
//

import SwiftUI

class AuthorMangasViewModel: ObservableObject {
    @Published var mangas: [MangaDTO] = []
    @Published var isLoading = false
    @Published var isLastPage = false
    @Published var currentPage = 1
    @Published var author: AuthorDTO

    private let api: APIService
    private let perPage = 20

    init(author: AuthorDTO, api: APIService = .shared) {
        self.author = author
        self.api = api
    }

    func loadNextPageIfNeeded(currentItem: MangaDTO?) async {
        guard !isLoading, !isLastPage else { return }
        if currentItem == nil || mangas.last?.id == currentItem?.id {
            await loadPage(currentPage + 1)
        }
    }

    func loadPage(_ page: Int) async {
        // Modificamos isLoading en el main thread para evitar problemas de concurrencia con @Published
        await MainActor.run {
            self.isLoading = true
        }
        do {
            let response = try await api.fetchMangasByAuthor(author.id, page: page, per: perPage)
            // Actualizamos las propiedades @Published en el main thread para mantener la coherencia con la UI
            await MainActor.run {
                if page == 1 {
                    mangas = response.data
                } else {
                    mangas.append(contentsOf: response.data)
                }
                currentPage = response.metadata.page
                isLastPage = response.data.isEmpty
                isLoading = false
            }
        } catch {
            // Actualizamos las propiedades @Published en el main thread incluso en caso de error
            await MainActor.run {
                print("Error cargando mangas de autor: \(error)")
                isLastPage = true
                isLoading = false
            }
        }
    }
}
