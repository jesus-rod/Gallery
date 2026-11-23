#if DEBUG
    import Foundation
    import GalleryCore

    struct StubImageHTTPClient: HTTPClient {
        private static let imageCount = 4

        func send(_ request: URLRequest) async throws -> (Data, HTTPURLResponse) {
            guard let url = request.url else { throw URLError(.badURL) }
            guard let data = fixtureImage(for: url) else {
                return (Data(), try response(for: url, statusCode: 404))
            }
            return (data, try response(for: url, statusCode: 200))
        }

        private func fixtureImage(for url: URL) -> Data? {
            guard url.host() == "images.unsplash.com",
                let number = Int(url.lastPathComponent.replacingOccurrences(of: "fixture-", with: ""))
            else { return nil }
            let index = (number - 1) % Self.imageCount + 1
            return Bundle.main.url(forResource: "fixture-image-\(index)", withExtension: "jpg")
                .flatMap { try? Data(contentsOf: $0) }
        }

        private func response(for url: URL, statusCode: Int) throws -> HTTPURLResponse {
            guard let response = HTTPURLResponse(url: url, statusCode: statusCode, httpVersion: nil, headerFields: nil)
            else { throw URLError(.badServerResponse) }
            return response
        }
    }
#endif
