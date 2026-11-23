import Foundation
import GalleryImageLoading
import Testing

@Suite(.trackingLeaks)
struct RemoteImageDataLoaderTests {
    @Test func load_requestsGivenURL() async throws {
        let url = URL(string: "https://images.example.com/a")!
        let fetch = FetchStub(result: .success((Data("image".utf8), response(200))))
        let sut = makeSUT(fetch)

        _ = try await sut.loadImageData(from: url)

        #expect(fetch.requestedURLs == [url])
    }

    @Test func load_deliversDataOn200WithNonEmptyBody() async throws {
        let data = Data("image".utf8)
        let sut = makeSUT(FetchStub(result: .success((data, response(200)))))

        #expect(try await sut.loadImageData(from: anyURL) == data)
    }

    @Test(arguments: [199, 201, 304, 404, 500])
    func load_throwsInvalidDataOnNon200(statusCode: Int) async {
        let sut = makeSUT(FetchStub(result: .success((Data("image".utf8), response(statusCode)))))

        await #expect(throws: RemoteImageDataLoader.Error.invalidData) {
            try await sut.loadImageData(from: anyURL)
        }
    }

    @Test func load_throwsInvalidDataOn200WithEmptyBody() async {
        let sut = makeSUT(FetchStub(result: .success((Data(), response(200)))))

        await #expect(throws: RemoteImageDataLoader.Error.invalidData) {
            try await sut.loadImageData(from: anyURL)
        }
    }

    @Test func load_rethrowsFetchError() async {
        let sut = makeSUT(FetchStub(result: .failure(URLError(.notConnectedToInternet))))

        await #expect(throws: URLError(.notConnectedToInternet)) {
            try await sut.loadImageData(from: anyURL)
        }
    }

    private func makeSUT(_ fetch: FetchStub, sourceLocation: SourceLocation = #_sourceLocation)
        -> RemoteImageDataLoader
    {
        let sut = RemoteImageDataLoader(fetch: fetch.fetch)
        trackForMemoryLeaks(fetch, sourceLocation: sourceLocation)
        return sut
    }

    private func response(_ statusCode: Int) -> HTTPURLResponse {
        HTTPURLResponse(url: anyURL, statusCode: statusCode, httpVersion: nil, headerFields: nil)!
    }
}

private final class FetchStub: @unchecked Sendable {
    private let lock = NSLock()
    private let result: Result<(Data, HTTPURLResponse), Error>
    private var _requestedURLs: [URL] = []

    var requestedURLs: [URL] { lock.withLock { _requestedURLs } }

    init(result: Result<(Data, HTTPURLResponse), Error>) {
        self.result = result
    }

    @Sendable func fetch(_ url: URL) async throws -> (Data, HTTPURLResponse) {
        lock.withLock { _requestedURLs.append(url) }
        return try result.get()
    }
}
