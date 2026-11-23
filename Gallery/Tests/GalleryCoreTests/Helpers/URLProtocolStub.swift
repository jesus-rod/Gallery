import Foundation

final class URLProtocolStub: URLProtocol {
    struct Stub {
        let data: Data?
        let response: URLResponse?
        let error: Error?
    }

    private final class Storage: @unchecked Sendable {
        private let lock = NSLock()
        private var stubs: [URL: Stub] = [:]
        private var requests: [URL: [URLRequest]] = [:]

        func stub(_ stub: Stub, for url: URL) {
            lock.withLock { stubs[url] = stub }
        }

        func record(_ request: URLRequest) -> Stub? {
            lock.withLock {
                guard let url = request.url else { return nil }
                requests[url, default: []].append(request)
                return stubs[url]
            }
        }

        func requests(for url: URL) -> [URLRequest] {
            lock.withLock { requests[url] ?? [] }
        }
    }

    private static let storage = Storage()

    static func stub(url: URL, data: Data? = nil, response: URLResponse? = nil, error: Error? = nil) {
        storage.stub(Stub(data: data, response: response, error: error), for: url)
    }

    static func requests(for url: URL) -> [URLRequest] {
        storage.requests(for: url)
    }

    static func makeSession() -> URLSession {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [URLProtocolStub.self]
        return URLSession(configuration: configuration)
    }

    override class func canInit(with request: URLRequest) -> Bool {
        true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    override func startLoading() {
        guard let stub = Self.storage.record(request) else {
            client?.urlProtocol(self, didFailWithError: URLError(.resourceUnavailable))
            return
        }
        if let error = stub.error {
            client?.urlProtocol(self, didFailWithError: error)
            return
        }
        if let response = stub.response {
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        }
        if let data = stub.data {
            client?.urlProtocol(self, didLoad: data)
        }
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}
}
