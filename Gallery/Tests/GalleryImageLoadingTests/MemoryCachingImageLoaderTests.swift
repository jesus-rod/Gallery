import CoreGraphics
import Foundation
import GalleryImageLoading
import Testing

@Suite(.trackingLeaks)
struct MemoryCachingImageLoaderTests {
    @Test func load_deliversDecorateeImage() async throws {
        let image = makeImage(width: 4, height: 2)
        let (sut, _) = makeSUT(result: .success(image))

        #expect(try await sut.loadImage(from: anyURL, maxPixelSize: 10) === image)
    }

    @Test func secondLoadOfSameKey_isServedFromMemory() async throws {
        let (sut, loader) = makeSUT()

        _ = try await sut.loadImage(from: anyURL, maxPixelSize: 10)
        _ = try await sut.loadImage(from: anyURL, maxPixelSize: 10)

        #expect(loader.requests == [ImageRequest(url: anyURL, maxPixelSize: 10)])
    }

    @Test func differentMaxPixelSize_isASeparateEntry() async throws {
        let (sut, loader) = makeSUT()

        _ = try await sut.loadImage(from: anyURL, maxPixelSize: 10)
        _ = try await sut.loadImage(from: anyURL, maxPixelSize: 20)

        #expect(
            loader.requests == [
                ImageRequest(url: anyURL, maxPixelSize: 10), ImageRequest(url: anyURL, maxPixelSize: 20),
            ])
    }

    @Test func failure_isNotCached() async throws {
        let (sut, loader) = makeSUT(result: .failure(AnyError()))

        _ = try? await sut.loadImage(from: anyURL, maxPixelSize: 10)
        _ = try? await sut.loadImage(from: anyURL, maxPixelSize: 10)

        #expect(loader.requests.count == 2)
    }

    @Test func removeAll_makesNextLoadGoToDecoratee() async throws {
        let (sut, loader) = makeSUT()

        _ = try await sut.loadImage(from: anyURL, maxPixelSize: 10)
        sut.removeAll()
        _ = try await sut.loadImage(from: anyURL, maxPixelSize: 10)

        #expect(loader.requests.count == 2)
    }

    @Test func cachedImage_isNilBeforeAnyLoad() {
        let (sut, _) = makeSUT()

        #expect(sut.cachedImage(from: anyURL, maxPixelSize: 10) == nil)
    }

    @Test func cachedImage_returnsTheImageAfterALoadOfTheSameURLAndSize() async throws {
        let image = makeImage(width: 4, height: 2)
        let (sut, _) = makeSUT(result: .success(image))

        _ = try await sut.loadImage(from: anyURL, maxPixelSize: 10)

        #expect(sut.cachedImage(from: anyURL, maxPixelSize: 10) === image)
        #expect(sut.cachedImage(from: anyURL, maxPixelSize: 20) == nil)
    }

    @Test func cachedImage_isNilAfterRemoveAll() async throws {
        let (sut, _) = makeSUT()
        _ = try await sut.loadImage(from: anyURL, maxPixelSize: 10)

        sut.removeAll()

        #expect(sut.cachedImage(from: anyURL, maxPixelSize: 10) == nil)
    }

    @Test func cachedImage_neverCallsTheDecoratee() async throws {
        let (sut, loader) = makeSUT()

        _ = sut.cachedImage(from: anyURL, maxPixelSize: 10)

        #expect(loader.requests.isEmpty)
    }

    private func makeSUT(
        result: Result<CGImage, Error> = .success(makeImage(width: 1, height: 1)),
        sourceLocation: SourceLocation = #_sourceLocation
    ) -> (MemoryCachingImageLoader, ImageLoaderStub) {
        let loader = ImageLoaderStub(result: result)
        let sut = MemoryCachingImageLoader(decoratee: loader, costLimit: 1_000_000)
        trackForMemoryLeaks(loader, sourceLocation: sourceLocation)
        trackForMemoryLeaks(sut, sourceLocation: sourceLocation)
        return (sut, loader)
    }
}
