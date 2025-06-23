//
//  MangaMapperTests.swift
//  MisMangasACA
//
//  Created by Juan Ignacio Antolini on 19/06/2025.
//


#if canImport(XCTest)
import XCTest
@testable import MisMangasACA
import SwiftData

// MARK: - Test stub loader (local al archivo para evitar dependencias externas)
private enum TestHelpers {
    /// Carga un JSON `filename.json` desde el bundle de tests y lo decodifica.
    static func loadStub<T: Decodable>(_ type: T.Type, from filename: String) throws -> T {
        let bundle = Bundle(for: MangaMapperTests.self)
        guard let url = bundle.url(forResource: filename, withExtension: "json") else {
            fatalError("❌ No se encontró el stub \(filename).json en el bundle de tests")
        }
        let data = try Data(contentsOf: url)
        return try JSONDecoder().decode(T.self, from: data)
    }
}

/// 📄 Pruebas de mapeo DTO → SwiftData (entidad)
final class MangaMapperTests: XCTestCase {
    // ⚙️ Contenedor en memoria para que el test no persista nada en disco
    private var container: ModelContainer!
    private var context: ModelContext!

    override func setUp() {
        container = try! ModelContainer(
            for: MangaEntity.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        context = ModelContext(container)
    }

    /// Verifica que insertar un DTO genere una `MangaEntity` válida
    func testMappingCreatesEntity() throws {
        // Carga stub JSON desde el bundle de tests
        let dto = try TestHelpers.loadStub(MangaDTO.self, from: "manga_stub")

        // Mapea y persiste en contexto
        let mapper = MangaMapper(context: context)
        let entity = mapper.insertOrUpdate(dto)

        // Assertions 🔍
        XCTAssertEqual(entity.id, dto.id)
        XCTAssertEqual(entity.genres.first?.name, dto.genres.first?.name)
    }
}
#endif
