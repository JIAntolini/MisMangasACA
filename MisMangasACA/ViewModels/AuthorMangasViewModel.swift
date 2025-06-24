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
        isLoading = true
        defer { isLoading = false }
        do {
            let response = try await api.fetchMangasByAuthor(author.id, page: page, per: perPage)
            if page == 1 {
                mangas = response.data
            } else {
                mangas.append(contentsOf: response.data)
            }
            currentPage = response.metadata.page
            isLastPage = response.data.isEmpty
        } catch {
            print("Error cargando mangas de autor: \(error)")
            isLastPage = true
        }
    }
}
