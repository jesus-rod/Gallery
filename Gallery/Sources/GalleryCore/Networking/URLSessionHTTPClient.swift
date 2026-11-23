import Foundation

public struct URLSessionHTTPClient: HTTPClient {
    public struct UnexpectedResponse: Error {}

    private let session: URLSession

    public init(session: URLSession) {
        self.session = session
    }

    public func send(_ request: URLRequest) async throws -> (Data, HTTPURLResponse) {
        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw UnexpectedResponse()
        }
        return (data, httpResponse)
    }
}
