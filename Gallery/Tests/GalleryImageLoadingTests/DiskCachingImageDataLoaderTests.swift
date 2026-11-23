import Foundation
import GalleryImageLoading
import Testing

@Suite(.trackingLeaks)
struct DiskCachingImageDataLoaderTests {
    @Test func load_deliversStoredDataWithoutLoadingFromDecoratee() async throws {
        let data = Data("stored".utf8)
        let (sut, loader, _) = makeSUT(store: ImageDataStoreStub(stored: [anyURL: data]))

        #expect(try await sut.loadImageData(from: anyURL) == data)
        #expect(loader.requestedURLs.isEmpty)
    }

    @Test func load_onMissDeliversAndStoresDecorateeData() async throws {
        let data = Data("remote".utf8)
        let (sut, _, store) = makeSUT(loaderResult: .success(data))

        #expect(try await sut.loadImageData(from: anyURL) == data)
        #expect(store.insertions == [Insertion(data: data, url: anyURL)])
    }

    @Test func load_treatsRetrievalErrorAsMiss() async throws {
        let data = Data("remote".utf8)
        let (sut, loader, _) = makeSUT(
            store: ImageDataStoreStub(retrievalError: AnyError()), loaderResult: .success(data))

        #expect(try await sut.loadImageData(from: anyURL) == data)
        #expect(loader.requestedURLs == [anyURL])
    }

    @Test func load_ignoresInsertionError() async throws {
        let data = Data("remote".utf8)
        let (sut, _, _) = makeSUT(store: ImageDataStoreStub(insertionError: AnyError()), loaderResult: .success(data))

        #expect(try await sut.loadImageData(from: anyURL) == data)
    }

    @Test func load_rethrowsDecorateeErrorAndStoresNothing() async {
        let (sut, _, store) = makeSUT(loaderResult: .failure(AnyError()))

        await #expect(throws: AnyError.self) { try await sut.loadImageData(from: anyURL) }
        #expect(store.insertions.isEmpty)
    }

    private func makeSUT(
        store: ImageDataStoreStub = ImageDataStoreStub(),
        loaderResult: Result<Data, Error> = .success(anyData()),
        sourceLocation: SourceLocation = #_sourceLocation
    ) -> (DiskCachingImageDataLoader, ImageDataLoaderStub, ImageDataStoreStub) {
        let loader = ImageDataLoaderStub(result: loaderResult)
        let sut = DiskCachingImageDataLoader(decoratee: loader, store: store)
        trackForMemoryLeaks(loader, sourceLocation: sourceLocation)
        trackForMemoryLeaks(store, sourceLocation: sourceLocation)
        return (sut, loader, store)
    }
}

struct Insertion: Equatable {
    let data: Data
    let url: URL
}

final class ImageDataStoreStub: ImageDataStore, @unchecked Sendable {
    private let lock = NSLock()
    private var stored: [URL: Data]
    private let retrievalError: Error?
    private let insertionError: Error?
    private var _insertions: [Insertion] = []

    var insertions: [Insertion] { lock.withLock { _insertions } }

    init(stored: [URL: Data] = [:], retrievalError: Error? = nil, insertionError: Error? = nil) {
        self.stored = stored
        self.retrievalError = retrievalError
        self.insertionError = insertionError
    }

    func retrieve(for url: URL) async throws -> Data? {
        if let retrievalError { throw retrievalError }
        return lock.withLock { stored[url] }
    }

    func insert(_ data: Data, for url: URL) async throws {
        if let insertionError { throw insertionError }
        lock.withLock {
            stored[url] = data
            _insertions.append(Insertion(data: data, url: url))
        }
    }
}

final class ImageDataLoaderStub: ImageDataLoader, @unchecked Sendable {
    private let lock = NSLock()
    private let result: Result<Data, Error>
    private var _requestedURLs: [URL] = []

    var requestedURLs: [URL] { lock.withLock { _requestedURLs } }

    init(result: Result<Data, Error>) {
        self.result = result
    }

    func loadImageData(from url: URL) async throws -> Data {
        lock.withLock { _requestedURLs.append(url) }
        return try result.get()
    }
}
