import Foundation

public struct RemoteImageDataLoader: ImageDataLoader {
    public typealias Fetch = @Sendable (URL) async throws -> (Data, HTTPURLResponse)

    public enum Error: Swift.Error, Equatable {
        case invalidData
    }

    private let fetch: Fetch

    public init(fetch: @escaping Fetch) {
        self.fetch = fetch
    }

    public func loadImageData(from url: URL) async throws -> Data {
        let (data, response) = try await fetch(url)
        guard response.statusCode == 200, !data.isEmpty else { throw Error.invalidData }
        return data
    }
}
