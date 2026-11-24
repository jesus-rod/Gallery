import Foundation
import GalleryComposition
import GalleryImageLoading
import Testing

final class ImagePipelineTests {
    private let directory = FileManager.default.temporaryDirectory
        .appending(path: "ImagePipelineTests-\(UUID().uuidString)")

    deinit {
        try? FileManager.default.removeItem(at: directory)
    }

    @Test func evictDiskCache_trimsLeastRecentlyUsedRenditionsToTheDiskLimitBeforeReturning() async throws {
        let oldest = URL(string: "https://images.example.com/oldest")!
        let older = URL(string: "https://images.example.com/older")!
        let newest = URL(string: "https://images.example.com/newest")!
        try await seedTenByteRenditions(usedInOrder: [oldest, older, newest])
        let sut = makeSUT(diskByteLimit: 15)

        await sut.evictDiskCache()

        let store = FileImageDataStore(directory: directory)
        #expect(try await store.retrieve(for: oldest) == nil)
        #expect(try await store.retrieve(for: older) == nil)
        #expect(try await store.retrieve(for: newest) == Data("0123456789".utf8))
    }

    // MARK: - Helpers

    private func makeSUT(diskByteLimit: Int) -> ImagePipeline {
        ImagePipeline(
            fetch: { _ in throw URLError(.notConnectedToInternet) },
            directory: directory,
            configuration: ImagePipelineConfiguration(
                memoryCostLimit: 1024,
                diskByteLimit: diskByteLimit,
                prefetchDistance: 0,
                previewSize: 8,
                renditionQuality: 75,
                fullScreenRenditionQuality: 80
            )
        )
    }

    private func seedTenByteRenditions(usedInOrder urls: [URL]) async throws {
        for (index, url) in urls.enumerated() {
            let usedAt = Date(timeIntervalSince1970: TimeInterval(index) * 60)
            let store = FileImageDataStore(directory: directory, currentDate: { usedAt })
            try await store.insert(Data("0123456789".utf8), for: url)
        }
    }
}
