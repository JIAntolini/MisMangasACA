//
//  MapperTests.swift
//  MisMangasACA
//
//  Created by Juan Ignacio Antolini on 21/06/2025.
//


import XCTest
import SwiftData
@testable import MisMangasACA

final class MapperTests: XCTestCase {

    func test_mangaDTO_toEntity_copiesFields() throws {
        // DTO mínimo
        let dto = MangaDTO(
            id: 42,
            title: "Test Manga",
            titleJapanese: nil,
            titleEnglish: nil,
            synopsis: nil,
            chapters: nil,
            volumes: nil,
            score: 9.9,
            status: "finished",
            startDate: nil,
            endDate: nil,
            mainPicture: "\"https://img.com/x.jpg\"",
            background: nil,
            url: nil,
            demographics: [],
            genres: [],
            themes: [],
            authors: []
        )

        // contenedor en memoria
        let container = try ModelContainer(
            for: Schema([MangaEntity.self]),
            configurations: [.init(isStoredInMemoryOnly: true)]
        )
        let context = ModelContext(container)

        let entity = MangaEntity(from: dto, context: context)

        XCTAssertEqual(entity.id, 42)
        XCTAssertEqual(entity.title, "Test Manga")
        XCTAssertEqual(entity.score, 9.9)
    }
}
