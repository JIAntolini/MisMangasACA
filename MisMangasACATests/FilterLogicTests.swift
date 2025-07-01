//
//  FilterLogicTests.swift
//  MisMangasACATests
//
//  Verifica que APIService.customSearch envíe el JSON correcto según los filtros.
//
import XCTest
@testable import MisMangasACA

// MARK: – Tests
final class FilterLogicTests: XCTestCase {

    override class func setUp() {
        super.setUp()
        URLProtocol.registerClass(URLProtocolStub.self)
    }

    override class func tearDown() {
        URLProtocol.unregisterClass(URLProtocolStub.self)
        super.tearDown()
    }

    /// Verifica que el body JSON coincide con los filtros seleccionados
    func testCustomSearchBodyMatchesFilters() async throws {

        // 1) Sesión con StubProtocol
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [URLProtocolStub.self]
        let session = URLSession(configuration: config)

        // 2) APIService con sesión inyectada
        let api = APIService(session: session)

        // 3) Expectación para asegurarnos de que se llamó el handler
        let exp = expectation(description: "Request capturada")

        // 4) Configuramos el handler
        URLProtocolStub.requestHandler = { req in
            // URL y método
            XCTAssertEqual(req.httpMethod, "POST")
            XCTAssertTrue(req.url?.path.hasSuffix("/search/manga") == true)

            // Body JSON
            let body = try XCTUnwrap(req.httpBody)
            let json = try JSONSerialization.jsonObject(with: body) as? [String: Any]
            XCTAssertEqual(json?["searchGenres"] as? [String], ["Action"])
            XCTAssertNil(json?["searchThemes"])
            XCTAssertEqual(json?["searchContains"] as? Bool, true)

            // Respuesta simulada
            let resp = HTTPURLResponse(
                url: req.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil)!
            exp.fulfill()
            return (resp, Data("""
                    {"items": [], "metadata": {"total":0,"page":1,"per":10}}
                    """.utf8))
        }

        // 5) Ejecutamos la búsqueda
        let search = CustomSearch(
            searchTitle: nil,
            searchAuthorIds: nil,
            searchAuthorFirstName: nil,
            searchAuthorLastName: nil,
            searchGenres: ["Action"],
            searchThemes: nil,
            searchDemographics: nil,
            searchContains: true
        )

        _ = try await api.customSearch(search, page: 1, per: 10)

        await fulfillment(of: [exp], timeout: 1.0)
    }
}
