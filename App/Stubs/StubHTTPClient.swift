#if DEBUG
    import Foundation
    import GalleryCore

    struct StubHTTPClient: HTTPClient {
        let isOffline: Bool

        private static let noSearchResults = Data(#"{"total":0,"total_pages":0,"results":[]}"#.utf8)

        init(isOffline: Bool = false) {
            self.isOffline = isOffline
        }

        func send(_ request: URLRequest) async throws -> (Data, HTTPURLResponse) {
            if isOffline { throw URLError(.notConnectedToInternet) }
            guard let url = request.url,
                let response = HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: nil)
            else { throw URLError(.badURL) }
            return (fixture(for: url), response)
        }

        private func fixture(for url: URL) -> Data {
            let page = queryValue(named: "page", in: url) ?? "1"
            guard url.path().hasSuffix("search/photos") else {
                return bundledJSON(named: "editorial-page-\(page)") ?? Data("[]".utf8)
            }
            let query = (queryValue(named: "query", in: url) ?? "").lowercased()
            return bundledJSON(named: "search-\(query)-page-\(page)") ?? Self.noSearchResults
        }

        private func queryValue(named name: String, in url: URL) -> String? {
            URLComponents(url: url, resolvingAgainstBaseURL: false)?
                .queryItems?
                .first { $0.name == name }?
                .value
        }

        private func bundledJSON(named name: String) -> Data? {
            Bundle.main.url(forResource: name, withExtension: "json")
                .flatMap { try? Data(contentsOf: $0) }
        }
    }
#endif
