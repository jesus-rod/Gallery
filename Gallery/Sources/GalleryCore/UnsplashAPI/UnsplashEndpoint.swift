import Foundation

public enum UnsplashEndpoint {
    case editorial(page: Int)
    case search(query: String, page: Int)

    public func request(baseURL: URL) -> URLRequest {
        switch self {
        case .editorial(let page):
            return makeRequest(baseURL: baseURL, path: "photos", queryItems: pageItems(page))
        case .search(let query, let page):
            let queryItems = [URLQueryItem(name: "query", value: query)] + pageItems(page)
            return makeRequest(baseURL: baseURL, path: "search/photos", queryItems: queryItems)
        }
    }

    private func pageItems(_ page: Int) -> [URLQueryItem] {
        [
            URLQueryItem(name: "page", value: String(page)),
            URLQueryItem(name: "per_page", value: "30"),
        ]
    }

    private func makeRequest(baseURL: URL, path: String, queryItems: [URLQueryItem]) -> URLRequest {
        let url = baseURL.appending(path: path)
        var components = URLComponents(url: url, resolvingAgainstBaseURL: false)!
        components.queryItems = queryItems
        let encodedQuery = components.percentEncodedQuery?.replacingOccurrences(of: "+", with: "%2B")
        components.percentEncodedQuery = encodedQuery
        return URLRequest(url: components.url!)
    }
}
