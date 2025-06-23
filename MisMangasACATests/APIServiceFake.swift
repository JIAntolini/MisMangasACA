//
//  APIServiceFake.swift
//  MisMangasACA
//
//  Created by Juan Ignacio Antolini on 21/06/2025.
//


import XCTest
@testable import MisMangasACA


final class APIServiceFake: APIService {
    private let page: PaginatedResponse<MangaDTO>

    init(page: PaginatedResponse<MangaDTO>) {
        self.page = page
        // no necesitamos sesión; llamamos al super init
        super.init()
    }

    override func fetchBestMangas(page: Int, per: Int = 10) async throws -> PaginatedResponse<MangaDTO> {
        return self.page
    }
}

@MainActor
final class HomeViewModelTests: XCTestCase {

    func test_loadFirstPage_populatesMangas() async throws {
        // 1. Fixture DTO
        let dto = MangaDTO(
            id: 1,
            title: "A",
            titleJapanese: nil,
            titleEnglish: nil,
            synopsis: nil,
            chapters: nil,
            volumes: nil,
            score: 9.0,
            status: "finished",
            startDate: nil,
            endDate: nil,
            mainPicture: nil,
            background: nil,
            url: nil,
            demographics: [],
            genres: [],
            themes: [],
            authors: []
        )
        let page = PaginatedResponse<MangaDTO>(data: [dto], metadata: .init(total: 1, page: 1, per: 10))

        // 2. VM con fake service
        let vm = HomeViewModel(api: APIServiceFake(page: page))

        // 3. Acción
        await vm.loadPage(1)

        // 4. Assert
        XCTAssertEqual(vm.mangas.count, 1)
        XCTAssertEqual(vm.currentPage, 1)
        XCTAssertFalse(vm.isLoadingPage)
    }
}
