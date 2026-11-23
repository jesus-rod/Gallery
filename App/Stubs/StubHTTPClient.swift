#if DEBUG
    import Foundation
    import GalleryCore

    struct StubHTTPClient: HTTPClient {
        func send(_ request: URLRequest) async throws -> (Data, HTTPURLResponse) {
            guard let url = request.url,
                let response = HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: nil)
            else { throw URLError(.badURL) }
            return (fixture(forPage: page(of: url)), response)
        }

        private func page(of url: URL) -> String {
            URLComponents(url: url, resolvingAgainstBaseURL: false)?
                .queryItems?
                .first { $0.name == "page" }?
                .value ?? "1"
        }

        private func fixture(forPage page: String) -> Data {
            Bundle.main.url(forResource: "editorial-page-\(page)", withExtension: "json")
                .flatMap { try? Data(contentsOf: $0) }
                ?? Data("[]".utf8)
        }
    }
#endif
