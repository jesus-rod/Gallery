import Foundation

public struct DiskCachingImageDataLoader: ImageDataLoader {
    private let decoratee: ImageDataLoader
    private let store: ImageDataStore

    public init(decoratee: ImageDataLoader, store: ImageDataStore) {
        self.decoratee = decoratee
        self.store = store
    }

    public func loadImageData(from url: URL) async throws -> Data {
        if let stored = try? await store.retrieve(for: url) {
            return stored
        }
        let data = try await decoratee.loadImageData(from: url)
        try? await store.insert(data, for: url)
        return data
    }
}
