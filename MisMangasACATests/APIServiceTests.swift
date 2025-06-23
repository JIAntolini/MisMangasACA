//
//  APIServiceTests.swift
//  MisMangasACA
//
//  Created by Juan Ignacio Antolini on 21/06/2025.
//

import XCTest
@testable import MisMangasACA   // permite que el test vea los tipos internos


final class APIServiceTests: XCTestCase {
    private var sut: APIService!   // System Under Test

    override func setUp() {
        super.setUp()
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [URLProtocolStub.self]
        let stubSession = URLSession(configuration: config)
        sut = APIService(session: stubSession)
    }

    override func tearDown() {
        sut = nil
        URLProtocolStub.unregister()
        super.tearDown()
    }

    // MARK: - Tests

    func test_fetchBestMangas_decodesPageOne() async throws {
        // 1️⃣  Carga fixture JSON desde el bundle de tests
        let bundle = Bundle(for: Self.self)
        guard let url = bundle.url(forResource: "best_mangas_page1", withExtension: "json") else {
            XCTFail("Fixture best_mangas_page1.json not found")
            return
        }
        let data = try Data(contentsOf: url)

        // 2️⃣  Registra el stub de red que devolverá el JSON con status 200
        let response = HTTPURLResponse(
            url: URL(string: "https://stub")!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )!
        URLProtocolStub.register(.init(data: data, response: response, error: nil))

        // 3️⃣  Ejecuta la petición
        let page = try await sut.fetchBestMangas(page: 1)

        // 4️⃣  Assertions básicas
        XCTAssertEqual(page.metadata.page, 1)
        XCTAssertEqual(page.data.count, 10)
        XCTAssertEqual(page.data.first?.id, 1)
    }
}
