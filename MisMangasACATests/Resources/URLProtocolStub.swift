//
//  URLProtocolStub.swift
//  MisMangasACA
//
//  Created by Juan Ignacio Antolini on 21/06/2025.
//


import Foundation

final class URLProtocolStub: URLProtocol {

    struct Stub {
        let data: Data?
        let response: HTTPURLResponse?
        let error: Error?
    }

    private static var stub: Stub?

    // MARK: Register / Unregister
    static func register(_ stub: Stub) {
        URLProtocolStub.stub = stub
        URLProtocol.registerClass(URLProtocolStub.self)
    }

    static func unregister() {
        URLProtocolStub.stub = nil
        URLProtocol.unregisterClass(URLProtocolStub.self)
    }

    // MARK: URLProtocol hooks
    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        guard let client = client, let stub = URLProtocolStub.stub else { return }

        if let response = stub.response {
            client.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        }
        if let data = stub.data {
            client.urlProtocol(self, didLoad: data)
        }
        if let error = stub.error {
            client.urlProtocol(self, didFailWithError: error)
        }
        client.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}
}
