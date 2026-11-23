import Foundation
import Testing

@testable import GalleryImageLoading

@Suite(.trackingLeaks)
struct ImagePrefetcherTests {
    private let a = URL(string: "https://images.example.com/a")!
    private let b = URL(string: "https://images.example.com/b")!
    private let c = URL(string: "https://images.example.com/c")!

    @Test func prefetch_startsALoadPerRequest() async {
        let (sut, spy) = makeSUT()

        sut.prefetch([request(a), request(b)])
        await spy.untilRequested(count: 2)

        #expect(Set(spy.requestedURLs) == [a, b])
        await cancelAll(sut, spy)
    }

    @Test func newWindow_cancelsLoadsNoLongerInItAndKeepsTheOthers() async {
        let (sut, spy) = makeSUT()

        sut.prefetch([request(a), request(b)])
        await spy.untilPending(count: 2)
        sut.prefetch([request(b), request(c)])
        await spy.untilRequested(count: 3)

        await eventually { spy.cancelledURLs == [a] }
        #expect(spy.cancelledURLs == [a])
        #expect(spy.requestedURLs.filter { $0 == b }.count == 1)
        #expect(spy.requestedURLs.contains(c))

        await cancelAll(sut, spy)
    }

    @Test func completedLoads_areDroppedFromBookkeeping() async {
        let (sut, spy) = makeSUT()

        sut.prefetch([request(a)])
        await spy.untilPending(count: 1)
        spy.complete(with: .success(pngData(width: 2, height: 2)), at: 0)

        await eventually { sut.inFlightCount == 0 }
        #expect(sut.inFlightCount == 0)
    }

    @Test func cancelledPrefetch_doesNotCancelAVisibleLoadSharingTheURL() async throws {
        let spy = ImageDataLoaderSpy()
        let dedup = InFlightDedupImageDataLoader(decoratee: spy)
        let loader = DownsamplingImageLoader(dataLoader: dedup)
        let sut = ImagePrefetcher(loader: loader)
        trackForMemoryLeaks(spy)
        trackForMemoryLeaks(dedup)
        trackForMemoryLeaks(sut)

        sut.prefetch([request(a)])
        await spy.untilPending(count: 1)
        let visible = Task { try await loader.loadImage(from: a, maxPixelSize: 10) }
        await eventually { dedup.waiterCount(for: a) == 2 }
        sut.prefetch([])
        await eventually { sut.inFlightCount == 0 }

        spy.complete(with: .success(pngData(width: 2, height: 2)), at: 0)

        let image = try await visible.value
        #expect(image.width == 2)
        #expect(spy.cancelledURLs.isEmpty)
    }

    private func cancelAll(_ sut: ImagePrefetcher, _ spy: ImageDataLoaderSpy) async {
        sut.prefetch([])
        await eventually { sut.inFlightCount == 0 && spy.pendingCount == 0 }
    }

    private func request(_ url: URL) -> ImagePrefetcher.Request {
        ImagePrefetcher.Request(url: url, maxPixelSize: 10)
    }

    private func makeSUT(sourceLocation: SourceLocation = #_sourceLocation) -> (ImagePrefetcher, ImageDataLoaderSpy) {
        let spy = ImageDataLoaderSpy()
        let sut = ImagePrefetcher(loader: DownsamplingImageLoader(dataLoader: spy))
        trackForMemoryLeaks(spy, sourceLocation: sourceLocation)
        trackForMemoryLeaks(sut, sourceLocation: sourceLocation)
        return (sut, spy)
    }
}
