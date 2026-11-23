import Foundation
import GalleryCore
import Testing

struct UnsplashEndpointTests {
    private let baseURL = URL(string: "https://base-url.com")!

    @Test func editorial_buildsRequestForPage() throws {
        let request = UnsplashEndpoint.editorial(page: 2).request(baseURL: baseURL)
        let components = try #require(request.url.flatMap { URLComponents(url: $0, resolvingAgainstBaseURL: false) })

        #expect(components.scheme == "https")
        #expect(components.host == "base-url.com")
        #expect(components.path == "/photos")
        #expect(
            Set(components.queryItems ?? []) == [
                URLQueryItem(name: "page", value: "2"),
                URLQueryItem(name: "per_page", value: "30"),
            ])
    }

    @Test func search_buildsRequestForPercentEncodedQueryAndPage() throws {
        let request = UnsplashEndpoint.search(query: "cats & dogs+birds", page: 3).request(baseURL: baseURL)
        let components = try #require(request.url.flatMap { URLComponents(url: $0, resolvingAgainstBaseURL: false) })

        #expect(components.scheme == "https")
        #expect(components.host == "base-url.com")
        #expect(components.path == "/search/photos")
        #expect(
            Set(components.percentEncodedQueryItems ?? []) == [
                URLQueryItem(name: "query", value: "cats%20%26%20dogs%2Bbirds"),
                URLQueryItem(name: "page", value: "3"),
                URLQueryItem(name: "per_page", value: "30"),
            ])
    }
}
